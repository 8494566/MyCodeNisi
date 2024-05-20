import os
import shutil
import json
import hashlib
import zipfile

from datetime import datetime
from pathlib import Path

from config import COPY_FILES, NO_COPY_FILES, INNER_COPY_FILES


class ExitCode:
    OK = 0
    CmdError = 1
    LostFile = 2
    ZipFailed = 3
    CheckMd5Failed = 4


def get_file_md5(fn):
    m = hashlib.md5()
    with open(fn, "rb") as fh:
        m.update(fh.read())
        fh.close()
    return m.hexdigest()


def generate_md5_file(zip_dir):
    md5_filepath = os.path.join(zip_dir, "md5.check")
    if os.path.exists(md5_filepath):
        os.remove(md5_filepath)

    print("getting md5")
    d = {}
    for root, dirs, files in os.walk(zip_dir):
        for f in files:
            fpath = os.path.join(root, f)
            relative_root = root[len(str(zip_dir)): len(root)]
            relative_path = os.path.join(relative_root, f)
            relative_path = relative_path.lstrip("\\")

            md5 = get_file_md5(fpath)
            d[relative_path] = md5
            print(relative_path, ": ", md5)

    print("writting to md5 file")
    with open(md5_filepath, "w") as f:
        json.dump(d, f, indent=2)


def extract_and_check_md5(zip_dir, dst_dir):
    unzip_dir = os.path.normpath(dst_dir) + "_tmp"
    zf = zipfile.ZipFile(zip_dir)
    zf.extractall(unzip_dir)

    try:
        # 判断有没有文件
        md5_file_path = os.path.join(unzip_dir, "md5.check")
        if not os.path.exists(md5_file_path):
            return False

        with open(md5_file_path, "r") as f:
            md5_dict = json.loads(f.read())

        if not md5_dict:
            return False

        md5Ok = True

        for fileName, md5Str in md5_dict.items():
            md5Str = md5Str.strip()
            filePath = os.path.join(unzip_dir, fileName)
            if not os.path.exists(filePath):
                print(f"no found file {filePath}")
                md5Ok = False

            md5 = get_file_md5(filePath)
            if md5 != md5Str:
                print(f"md5 check failed, file {filePath}")
                md5Ok = False

        return md5Ok
    except Exception as err:
        print(err)
    finally:
        shutil.rmtree(unzip_dir)

    return False


def pack(stable_path, version, output_path, make_inner):
    zip_name = f"CCVoiceHub-{datetime.now().strftime(u'%Y%m%d%H%M%S')}-{version}-stable"
    dst_dir = os.path.join(output_path, zip_name)
    makeDir(dst_dir)

    stable_path = Path(stable_path)
    dst_dir = Path(dst_dir)

    # 拷贝
    for i in COPY_FILES:
        src = stable_path.joinpath(i)
        dst = dst_dir.joinpath(i)
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
            sys.exit(ExitCode.LostFile)

    # api-ms-win-xx运行库
    for f in os.listdir(stable_path):
        if f in NO_COPY_FILES:
            continue

        if (not make_inner) and f in INNER_COPY_FILES:
            continue

        name, ext = os.path.splitext(f)
        if name.startswith("api-ms-win-") or ext in [".dll", ".exe", ".pyd", ".json"]:
            print("copy {}".format(f))
            shutil.copyfile(stable_path.joinpath(f), dst_dir.joinpath(f))

    # 生成md5文件
    generate_md5_file(dst_dir)

    # zip压缩
    print(f"{zip_name} 文件压缩中...")
    zip_path = shutil.make_archive(os.path.join(output_path, zip_name), "zip", dst_dir)
    if not os.path.exists(zip_path):
        print("压缩失败!请检查!")
        sys.exit(ExitCode.ZipFailed)
    else:
        print(f"{zip_name} 解压文件完成")

    # 尝试解压并校验md5
    print("解压校验md5中...")
    md5_ok = extract_and_check_md5(zip_path, dst_dir)
    if not md5_ok:
        print("解压和校验md5失败")
        sys.exit(ExitCode.CheckMd5Failed)
    else:
        print("解压和校验md5成功")

    return zip_name


def makeDir(path: str):
    isExists = os.path.exists(path)
    if isExists:
        print(f"{path} 目录存在，准备删除")
        shutil.rmtree(path)

    os.makedirs(path)
    print(f'{path}创建成功')


def main(stable_path, version, output_path, make_inner):
    if not os.path.isdir(stable_path):
        print(f"{stable_path} 路径不存在")

    zip_name = pack(stable_path, version, output_path, make_inner)

    print("删除解压文件夹...")
    zip_dir = os.path.join(output_path, zip_name)
    if os.path.isdir(zip_dir):
        shutil.rmtree(zip_dir)

    zip_path = os.path.join(output_path, f"{zip_name}.zip")
    assert os.path.exists(zip_path)

    with open(os.path.join(output_path, "_outZipName.txt"), "w") as f:
        f.write(zip_name)
    return 0


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 4:
        print("usage: {stable_path} {update_version} {output_path} {make_inner}")
        sys.exit(1)

    stable_path = sys.argv[1]
    version = sys.argv[2]
    output_path = sys.argv[3]
    make_inner = sys.argv[4] == "1"

    main(stable_path, version, output_path, make_inner)
