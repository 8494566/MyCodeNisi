from base.notify import Notify
from base.util import Util
from ccvoicehub_pkg_installer.installer_builder import InstallerBuilder

if __name__ == "__main__":
    import client_config
    client_config.LOCAL_DEBUG = False

    builder = InstallerBuilder()
    character_str = builder.get_new_character_text()
    builder.set_new_character_text(character_str)
    branch, svn_version, inner_version, outer_version, make_inner, upload_gdl = "master", "294949", "100002", "1.0.2", False, False
    msg = builder.build(branch, svn_version, inner_version, outer_version, make_inner, upload_gdl)
    print(msg)
