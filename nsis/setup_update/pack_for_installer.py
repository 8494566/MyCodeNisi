import os
import sys
import json
import subprocess
import shutil

from pathlib import Path

from config import COPY_FILES, NO_COPY_FILES, INNER_COPY_FILES

EXCLUDED_FILES = [
    "vcruntime140.dll",
    "ucrtbase.dll",
    "msvcp140.dll",
    "msvcp140_1.dll",
    "msvcp140_2.dll",
    "libcrypto-1_1.dll",
    "libssl-1_1.dll",
    "libcurl.dll",
    "opengl32sw.dll",
]

work_dir = Path(__file__).absolute().parent.parent

signtool = work_dir.joinpath("./setup_update/signtool.exe")
if not os.path.exists(signtool):
    print("signtool.exe not exist")
    exit(99)

rartool = work_dir.joinpath("./setup_update/Rar.exe")
if not os.path.exists(rartool):
    print("Rar.exe not exist")
    exit(100)


CHECK_SIGN = 1


def check_file_sign(f):
    cmd = "\"{}\" verify /a /pa \"{}\"".format(str(signtool), f)
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT)
    out, err = p.communicate()
    return out.find(b"Successfully verified") != -1


def check_sign(work_dir):
    fs = []
    for root, dirs, files in os.walk(work_dir):
        if root.endswith("setup_update"):
            continue
        for f in files:
            if f.startswith("api-ms-win-"):
                continue
            if f in EXCLUDED_FILES:
                continue
            name, ext = os.path.splitext(f)
            if ext not in [".dll", ".exe", ".pyd"]:
                continue
            fs.append(os.path.join(root, f))

    unsign_fs = []
    for i, f in enumerate(fs):
        print("[{:3d}|{:3d}] checking signature {}".format(i + 1, len(fs), f))
        if not check_file_sign(f):
            unsign_fs.append(f)

    unsign_fs = [f[len(str(work_dir)) + 1:] for f in unsign_fs]
    unsign_fs = set(unsign_fs) - set(EXCLUDED_FILES)
    if len(unsign_fs):
        print("\n************************")
        for f in unsign_fs:
            print(f)
        print(f"************************\ncheck fail: files above are not signed. {str(f)}")
    else:
        print("\ncheck suc: all files are signed.")

    return len(unsign_fs) == 0


def pack(target, version="10000", make_inner=False):
    # 检查签名
    if CHECK_SIGN:
        if not check_sign(work_dir):
            return 1

    src_dir = work_dir
    dst_dir = target

    with open("version.json", 'w', encoding="utf-8") as f:
        data = {
            "version": str(version)
        }
        f.write(json.dumps(data, indent=4))

    # 创建文件夹
    folder_name = version.strip()
    folder_path = dst_dir / folder_name

    if folder_path.exists() and folder_path.is_dir():
        os.rmdir(str(folder_path))  # 确保路径存在且为文件夹时才删除
    os.mkdir(str(folder_path))

    # 拷贝
    for i in COPY_FILES:
        src = src_dir.joinpath(i)
        dst = folder_path.joinpath(i)
        print("copy {}".format(i))
        if os.path.isfile(src):
            parent = os.path.dirname(dst)
            if not os.path.exists(parent):
                os.makedirs(parent)
            shutil.copyfile(src, dst)
        elif os.path.isdir(src):
            shutil.copytree(src, dst)
        else:
            print("not exist {}".format(i))
            return 2

    # api-ms-win-xx运行库
    for f in os.listdir(work_dir):
        if f in NO_COPY_FILES:
            continue

        if (not make_inner) and f in INNER_COPY_FILES:
            continue

        name, ext = os.path.splitext(f)
        if name.startswith("api-ms-win-") or ext in [".dll", ".exe", ".pyd", ".json"]:
            print("copy {}".format(f))
            if name in ["CCVoicehubLauncher", "version"]:
                shutil.copyfile(work_dir.joinpath(f), dst_dir.joinpath(f))
            else:
                shutil.copyfile(work_dir.joinpath(f), folder_path.joinpath(f))

    # 压缩
    base_name = os.path.basename(dst_dir)
    rar_file = "{}.rar".format(base_name)
    if os.path.isfile(rar_file):
        os.remove(rar_file)
    cmd = [str(rartool), "a", "-r", "-msrar;zip;jpg;jpeg;gif;rm;rmvb;mp3;wave;wam;wmv;mpeg", rar_file, base_name]
    print(subprocess.list2cmdline(cmd))
    print(os.path.dirname(dst_dir))
    p = subprocess.Popen(cmd, cwd=os.path.dirname(dst_dir))
    p.communicate()
    return 0


def main(target, version="10000", make_inner=False):
    target_dir = Path(__file__).absolute().parent.joinpath(target)
    target_dir = Path(os.path.normpath(target_dir))
    print("将打包在相对路径：{} 绝对路径: {}".format(target, target_dir))
    if os.path.exists(target_dir):
        print("已经存在相同目录，覆盖")
        shutil.rmtree(target_dir)

    os.makedirs(target_dir)
    return pack(target_dir, version, make_inner)


def handle_exception(exc_type, exc_value, exc_traceback):
    sys.__excepthook__(exc_type, exc_value, exc_traceback)
    sys.exit(101)


PACK_DIR = "release"
if __name__ == "__main__":

    sys.excepthook = handle_exception

    if len(sys.argv) > 3:
        make_inner = sys.argv[3] == "1"
        ret_code = main(sys.argv[1], sys.argv[2], make_inner)
    else:
        ret_code = main(PACK_DIR)
    sys.exit(ret_code)

# ../../bin
