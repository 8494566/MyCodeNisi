import os
import sys
import base64
import shutil
import traceback
import datetime
from pathlib import Path
from base.notify import Notify
from base.util import Util
from base.mssign.mssign_new import NewMSSign
from base.vcs import create_vcs
from base import subprocess_v1
from base.gdl_upload import gdl_upload_file

from ccvoicehub_pkg_installer.installer_builder_config import CCVOICEHUB_BRANCH_DICT

CHARACTER_FILE = str(Path(__file__).absolute().parent.joinpath("tools/cc res/NewCharacter.txt"))
BAT_FILE = str(Path(__file__).absolute().parent.joinpath("packet.bat"))


class UpdateResult:
    def __init__(self):
        self.succ = False
        self.local_path = ""
        self.log_name = ""
        self.zip_name = ""
        self.zip_md5 = ""
        self.gdl_url = ""
        self.reason = ""


def getMD5ByChunk(fpath, logger=None, blockSize=2 ** 20):
    # blockSize 一次读取的大小，2**20 为 1M
    import hashlib
    m = hashlib.md5()
    try:
        with open(fpath, "rb") as f:
            while True:
                buf = f.read(blockSize)
                if not buf:
                    break
                m.update(buf)
        md5_actual = m.hexdigest()
        return md5_actual
    except Exception as e:
        if logger:
            logger.error("fail to calculate md5. {}".format(traceback.format_exc()))
        return "-"


class InstallerBuilder(object):
    def __init__(self):
        self.branch = None
        self.svn_version = None
        self.inner_version = None
        self.outer_version = None
        self.make_inner = "0"
        self.update_upload_gdl = False

    def get_new_character_text(self):
        character_str = ""
        try:
            with open(CHARACTER_FILE, "r") as f:
                character_str = f.read()
        except:
            Notify.post_fatal_error("cc_installer_build", traceback.format_exc())
        base64Text = base64.b64encode(character_str.encode("gbk"))
        return base64Text

    def set_new_character_text(self, base64Text):
        character_str = base64.b64decode(base64Text).decode("gbk")
        try:
            with open(CHARACTER_FILE, "w") as f:
                f.write(character_str)
        except:
            Notify.post_fatal_error("ccvoice_installer_build", traceback.format_exc())

    def build(self, branch, svn_version, inner_version, outer_version, make_inner, update_upload_gdl):
        assert branch in CCVOICEHUB_BRANCH_DICT
        self.branch = branch
        self.svn_version = svn_version
        self.inner_version = inner_version
        self.outer_version = outer_version
        self.make_inner = "1" if make_inner == "1" else "0"
        self.update_upload_gdl = True if update_upload_gdl == "1" else False
        inner_str = "内网包" if make_inner == "1" else "外网包"
        msg = ""

        # 安装包
        filename, reason, log_name = self.make_pkg()
        if not filename:
            msg = f"CC开黑安装包制作失败 {branch}-{svn_version}-{inner_version}-{outer_version}-{inner_str}\n{reason}"
            msg += "，点击查看日志"
            log_path = f"api/build/log/{log_name}"
            msg += Util.makeup_url(log_path)
            return msg

        msg = f"CC开黑安装包制作成功 {branch}-{svn_version}-{inner_version}-{outer_version}-{inner_str}"
        url_path = f"api/build/installer/download/{filename}"
        url = Util.makeup_url(url_path)
        msg += f"\n安装包下载地址: {url}"

        msg += "\n"
        # 更新包
        update_ret = self.make_update()
        if not update_ret.succ:
            msg += f"\nCC开黑更新包制作失败 {branch}-{svn_version}-{inner_version}-{outer_version}\n{update_ret.reason}"
            msg += "，点击查看日志"
            log_path = f"api/build/log/{update_ret.log_name}"
            msg += Util.makeup_url(log_path)
            return msg
        pack_download_url = Util.makeup_url(f"api/build/updater/download/{update_ret.zip_name}.zip")
        msg += f"\nCC开黑更新包内网下载地址: {pack_download_url}"
        msg += f"\n更新包md5: {update_ret.zip_md5}"

        if update_ret.gdl_url:
            msg += f"\n更新包gdl下载地址: {update_ret.gdl_url}"
        return msg

    def make_pkg(self):
        svn_url = CCVOICEHUB_BRANCH_DICT[self.branch][1]
        local_dir = svn_url.split("/")[-1]
        log_file, log_name = Util.prepare_log(f"ccvoicehub-pkg-{self.svn_version}-{self.inner_version}-{self.outer_version}")

        from base import subprocess_v1
        ret_code = subprocess_v1.Popen([BAT_FILE, local_dir, self.svn_version, svn_url, self.inner_version, self.make_inner],
                                      cwd=os.getcwd(),
                                      logger=log_file)
        log_file.close()
        print("ret_code: ", ret_code)
        error = {
            1: "有未签名文件",
            2: "有缺失文件",
            99: "signtool.exe不存在",
            100: "Rar.exe不存在",
            101: "其他异常",
        }
        if ret_code != 0:
            return "", error.get(ret_code, "未知错误"), log_name

        src_installer_file = os.path.join(os.path.dirname(__file__), "ccvoice_pkg_installer.exe")
        if not os.path.exists(src_installer_file):
            print("not find ccvoice_pkg_installer.exe")
            return "", "找不到ccvoice_pkg_installer.exe", log_name

        installer_name = f"CCVoice_Setup_{self.outer_version}_{self.inner_version}_{self.svn_version}.exe"
        installer_save_dir = os.path.join(Util.get_output_dir(), "cc_installer")
        if not os.path.isdir(installer_save_dir):
            os.makedirs(installer_save_dir)
        dst_installer_file = os.path.join(installer_save_dir, installer_name)
        if os.path.exists(dst_installer_file):
            os.remove(dst_installer_file)
        shutil.copyfile(src_installer_file, dst_installer_file)
        os.remove(src_installer_file)

        # 打签名
        ms = NewMSSign()
        if not ms.sign([dst_installer_file]):
            print("签名失败")
            return "", "签名失败", log_name

        return installer_name, "", log_name

    def make_update(self):
        ret = UpdateResult()
        time_str = datetime.datetime.now().strftime('%Y%m%d%H%M%S')
        sub_dir = f"CCVoicehub-{self.inner_version}-{self.outer_version}-{self.branch}-{time_str}"
        work_path = Util.join_path("tmp/ccvoicehub_update")
        output_path = os.path.join(Util.get_output_dir(), "cc_updater")
        if not os.path.isdir(work_path):
            os.makedirs(work_path)

        checkout_path = os.path.join(Util.join_path("tmp/ccvoicehub_update"), sub_dir)
        svn_url = CCVOICEHUB_BRANCH_DICT[self.branch][1]
        repo = create_vcs("svn", svn_url, checkout_path)
        repo.pull()
        repo.checkout_version_v2(self.svn_version)

        py_script = os.path.join(repo.path, "setup_update/pack_for_update.py")
        py_exe = sys.executable
        cmds = f"{py_exe} {py_script} {repo.path} {self.inner_version} {output_path} {self.make_inner}"
        print(cmds)
        log_file, log_name = Util.prepare_log(f"ccvoicehub-update-{self.svn_version}-{self.inner_version}-{self.outer_version}")

        ret_code = subprocess_v1.Popen(cmds, cwd=os.path.dirname(py_script), logger=log_file)
        log_file.close()

        ret.log_name = log_name

        if ret_code != 0:
            ret.reason = f"进程执行失败，错误码: {ret_code}"
            return ret

        output_file = os.path.join(output_path, "_outZipName.txt")
        zip_name = open(output_file, "r", encoding="utf-8").read()
        print("zip_name:", zip_name)

        zip_path = os.path.join(output_path, f"{zip_name}.zip")
        if not os.path.exists(zip_path):
            ret.reason = f"找不到{zip_path}"
            return

        ret.zip_name = zip_name
        ret.local_path = zip_path
        ret.zip_md5 = getMD5ByChunk(zip_path)

        if self.update_upload_gdl:
            # 上传gdl
            import client_config
            if not client_config.LOCAL_DEBUG:
                url = gdl_upload_file(zip_path, f"{zip_name}.zip")
                ret.gdl_url = url

        ret.succ = True

        return ret
