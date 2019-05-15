# Package

version       = "0.1.0"
author        = "Robert McDermott"
description   = "Takes pwalk output and generates file age (mtime or atime) histogram of file age breakdown by file count and volume."
license       = "Apache-2.0"
srcDir        = "src"
bin           = @["home_stats"]


# Dependencies

requires "nim >= 0.19.0"
