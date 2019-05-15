# This program parses the output of pwalk and generates file statistics 
# The format of the pwalk input files is as follows:
# inode,parent-inode,directory-depth,filename,fileExtension,UID,GID,st_size,st_dev,st_blocks,st_nlink,st_mode,st_atime,st_mtime,st_ctime,pw_fcount,pw_dirsum 
# [(0, 'inode'), (1, 'parent-inode'), (2, 'directory-depth'), (3, 'filename'), (4, 'fileExtension'), (5, 'UID'), (6, 'GID'), (7, 'st_size'), (8, 'st_dev'), (9, 'st_blocks'), (10, 'st_nlink'), (11, 'st_mode'), (12, 'st_atime'), (13, 'st_mtime'), (14, 'st_ctime'), (15, 'pw_fcount'), (16, 'pw_dirsum')]

import strutils, strformat, tables, times, algorithm, parseutils, math, commandeer

# get the current time in seconds since epoch
var now = int(epochTime())

# main function where all the action takes place
proc main() =
    commandline:
      argument pwalkfile, string
      option atime, bool, "atime", "a", false
      option offsetdays, int, "offsetdays", "o", 0
      exitoption "help", "h", "Usage: pwalk-reporter [--atime] [--offsetdays <int>] <pwalkoutput.csv>"
      errormsg "Error: please use --help for usage information"

    # mtime file count histogram
    var mage_hist_count = {1:0, 2:0, 4:0, 7:0, 14:0, 31:0, 62:0, 120:0, 180:0, 365:0, 730:0, 1095:0,
    1460:0, 1825:0, 2190:0, 2555:0, 2920:0, 3285:0, 3650:0, 4015:0, 4380:0,
    4745:0, 5110:0, 5475:0, 7300:0, 10950:0}.toTable

    var mage_hist_size = {1:0.0, 2:0.0, 4:0.0, 7:0.0, 14:0.0, 31:0.0, 62:0.0, 120:0.0, 180:0.0, 365:0.0, 730:0.0, 1095:0.0,
    1460:0.0, 1825:0.0, 2190:0.0, 2555:0.0, 2920:0.0, 3285:0.0, 3650:0.0, 4015:0.0, 4380:0.0,
    4745:0.0, 5110:0.0, 5475:0.0, 7300:0.0, 10950:0.0}.toTable

    # keep track of file types
    var exts = initTable[string, float64]()
    var dirs = initTable[string, float64]()

    # keep track of total file count and size
    var total_files: int64
    var total_size: float64

    # start with offset time? usefull when working with older pwalk input data
    if offsetdays != 0:
        now =  now - (offsetdays * 86400)

    # interate of lines in file and then chars in lines and build dictionary of char freqency
    for line in lines(pwalkfile):
        var l: seq[string] = line.split("|")
        
        # Skip directory entries for file stats, but gather directory sizes 
        try:
            if l[15] != "-1":
                var dirsize = (parseInt(l[16]) / 1024) / 1024 / 1024
                if dirsize >= 1:  # only count directoires if they are above 1GB in size
                    dirs[l[3].toLower] = dirsize
                continue
        except:
            continue
        
        var mage: int
        var size: float64
        try:
            # defaults to mtime but will use atime if --atime flag is used
            if atime == false:
                mage = (now - parseint(l[13]))
            else:
                mage = (now - parseint(l[12]))
            size = (parseInt(l[7]) / 1024) / 1024 / 1024
        except:
            continue

        # keep a running total of file count and size
        total_files += 1
        total_size += size

        var ext: string
        try:
            # keep a running total of file extensions
            ext = l[4].replace("\"", "").toLower
            if ext.len == 0:
                ext = "noext"
        except:
            continue

        if ext in exts:
            exts[ext] += size
        else:
            exts[ext] = size

        # populate the modification count and volume histograms
        if mage <= 0:  #some files had bogus mtimes (in the future)
            continue
        if mage <= 86400:
            mage_hist_count[1] += 1
            mage_hist_size[1] += size
        elif mage <= 172800:
            mage_hist_count[2] += 1
            mage_hist_size[2] += size
        elif mage <= 345600:
            mage_hist_count[4] += 1
            mage_hist_size[4] += size
        elif mage <= 604800:
            mage_hist_count[7] += 1
            mage_hist_size[7] += size
        elif mage <= 1209600:
            mage_hist_count[14] += 1
            mage_hist_size[14] += size
        elif mage <= 2678400:
            mage_hist_count[31] += 1
            mage_hist_size[31] += size
        elif mage <= 5356800:
            mage_hist_count[62] += 1
            mage_hist_size[62] += size
        elif mage <= 10368000:
            mage_hist_count[120] += 1
            mage_hist_size[120] += size
        elif mage <= 15552000:
            mage_hist_count[180] += 1
            mage_hist_size[180] += size
        elif mage <= 31536000:
            mage_hist_count[365] += 1
            mage_hist_size[365] += size
        elif mage <= 63072000:
            mage_hist_count[730] += 1
            mage_hist_size[730] += size
        elif mage <= 94608000:
            mage_hist_count[1095] += 1
            mage_hist_size[1095] += size
        elif mage <= 126144000:
            mage_hist_count[1460] += 1
            mage_hist_size[1460] += size
        elif mage <= 157680000:
            mage_hist_count[1825] += 1
            mage_hist_size[1825] += size
        elif mage <= 189216000:
            mage_hist_count[2190] += 1
            mage_hist_size[2190] += size
        elif mage <= 220752000:
            mage_hist_count[2555] += 1
            mage_hist_size[2555] += size
        elif mage <= 252288000:
            mage_hist_count[2920] += 1
            mage_hist_size[2920] += size
        elif mage <= 283824000:
            mage_hist_count[3285] += 1
            mage_hist_size[3285] += size
        elif mage <= 315360000:
            mage_hist_count[3650] += 1
            mage_hist_size[3650] += size
        elif mage <= 346896000:
            mage_hist_count[4015] += 1
            mage_hist_size[4015] += size
        elif mage <= 378432000:
            mage_hist_count[4380] += 1
            mage_hist_size[4380] += size
        elif mage <= 409968000:
            mage_hist_count[4745] += 1
            mage_hist_size[4745] += size
        elif mage <= 441504000:
            mage_hist_count[5110] += 1
            mage_hist_size[5110] += size
        elif mage <= 473040000:
            mage_hist_count[5475] += 1
            mage_hist_size[5475] += size
        elif mage <= 630720000:
            mage_hist_count[7300] += 1
            mage_hist_size[7300] += size
        elif mage <= 946080000:
            mage_hist_count[10950] += 1
            mage_hist_size[10950] += size

    
    # sort the keys by age
    var bins: seq[int]
    for k in mage_hist_size.keys:   
        bins.add(k)
    bins.sort(system.cmp[int])
    
    # output file age histogram data to stdout
    echo "sep=,"
    echo "Total files, Total size (GiB)"
    echo &"{total_files}, {total_size.formatFloat(ffDecimal, 2)}\n\n"

    if atime == true:
        echo "# NOTE: figures below are for access time (atime) ages."
    else:
        echo "# NOTE: figures below are for modification time (mtime) ages (default); use '--atime' flag for access time stats"
    echo "Age Days, Size (GiB), File Count"
    for bin in bins:
        echo &"{bin}, {mage_hist_size[bin].formatFloat(ffDecimal, 2)}, {mage_hist_count[bin]}"
    

    # to sort the dictionay by value
    # create a seq of tuples with the key and values reversed
    var revpairs: seq[(float64, string)]
    for x in exts.pairs:
        revpairs.add((x[1], x[0]))

    # sort the seq by extension freqency then reverse it to get decending order
    revpairs.sort(system.cmp)
    reverse(revpairs)

    # output file type statistics to stdout
    echo "\n\n# Top 100 file types"
    echo "File Extension, Size (GiB)"
    # interate over the dictionary using the sorted keys to get a descending sorted extension freqency report
    var count = 0
    var others: float64 = 0
    for x in revpairs:
        if count >= 100:
            others += exts[x[1]]
        else:
            echo &"{x[1]}, {exts[x[1]].formatFloat(ffDecimal, 2)}"
        count += 1
    echo &"all-other-types, {others.formatFloat(ffDecimal, 2)}"


    # top 100 largest directories
    echo "\n\n# Top 100 largest directories"
    echo "Directory, Size (GiB)"
    var revpairs_d: seq[(float64, string)]
    for d in dirs.pairs:
        revpairs_d.add((d[1], d[0]))
    revpairs_d.sort(system.cmp)
    reverse(revpairs_d)
    var count_d = 0
    for dir in revpairs_d:
        if count_d >= 100:
            break
        echo &"{dir[1]}, {dirs[dir[1]].formatFloat(ffDecimal, 2)}"
        count_d += 1

# execution starts here
when isMainModule:
    main()
