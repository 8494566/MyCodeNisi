from base.util import Util

CCVOICEHUB_SVN_TRUNK = ["svn",
                        "https://svn-cc.gz.netease.com/release/cc/client/ccvoicehub_pkg",
                        str(Util.join_path("tmp/python_app/ccvoicehub/pack/dev"))]

CCVOICEHUB_SVN_STABLE = ["svn",
                         "https://svn-cc.gz.netease.com/release/cc/client/ccvoicehub_stable",
                         str(Util.join_path("tmp/python_app/ccvoicehub/pack/master"))]

CCVOICEHUB_BRANCH_DICT = {
    "dev": CCVOICEHUB_SVN_TRUNK,
    "master": CCVOICEHUB_SVN_STABLE,
}
