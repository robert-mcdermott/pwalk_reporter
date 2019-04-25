# This program parses the output of pwalk and generates file statistics 
# The format of the pwalk input files is as follows:
# inode,parent-inode,directory-depth,filename,fileExtension,UID,GID,st_size,st_dev,st_blocks,st_nlink,st_mode,st_atime,st_mtime,st_ctime,pw_fcount,pw_dirsum 
# [(0, 'inode'), (1, 'parent-inode'), (2, 'directory-depth'), (3, 'filename'), (4, 'fileExtension'), (5, 'UID'), (6, 'GID'), (7, 'st_size'), (8, 'st_dev'), (9, 'st_blocks'), (10, 'st_nlink'), (11, 'st_mode'), (12, 'st_atime'), (13, 'st_mtime'), (14, 'st_ctime'), (15, 'pw_fcount'), (16, 'pw_dirsum')]


import strutils, strformat, tables, times, algorithm, parseutils, math, commandeer
var now = int(epochTime())

proc main() =
    commandline:
      argument pwalkfile, string
      exitoption "help", "h", "Usage: pwalk-reporter <pwalkoutput.csv>"
      errormsg "Error: please use --help for usage information"

    # mtime file count histogram
    var mage_hist_count = {1:0, 2:0, 4:0, 7:0, 14:0, 31:0, 62:0, 120:0, 180:0, 365:0, 730:0, 1095:0,
    1460:0, 1825:0, 2190:0, 2555:0, 2920:0, 3285:0, 3650:0, 4015:0, 4380:0,
    4745:0, 5110:0, 5475:0, 7300:0, 10950:0}.toTable

    var mage_hist_size = {1:0.0, 2:0.0, 4:0.0, 7:0.0, 14:0.0, 31:0.0, 62:0.0, 120:0.0, 180:0.0, 365:0.0, 730:0.0, 1095:0.0,
    1460:0.0, 1825:0.0, 2190:0.0, 2555:0.0, 2920:0.0, 3285:0.0, 3650:0.0, 4015:0.0, 4380:0.0,
    4745:0.0, 5110:0.0, 5475:0.0, 7300:0.0, 10950:0.0}.toTable

    # interate of lines in file and then chars in lines and build dictionary of char freqency
    for line in lines(pwalkfile):
        var l: seq[string] = line.split("|")
        # Skip directories
        if l[15] != "-1":
            continue
        #var aage = ((now - parseint(l[12])) div 86400)
        #var mage = ((now - parseint(l[13])) div 86400)
        var aage = (now - parseint(l[12]))
        var mage = (now - parseint(l[13]))
        var size = (parseInt(l[7]) / 1024) / 1024 / 1024

        # populate the modification count and volume histograms
        if mage <= 0:  #some files had bogus mtimes (in the future)
            continue
        if mage <= 86400:
            echo line
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
    
    # Out to stdout in CSV format
    echo "sep=,"
    echo "Age Days, Size (GiB)"
    for bin in bins:
        echo &"{bin}, {mage_hist_size[bin].formatFloat(ffDecimal, 2)}"
    
when isMainModule:
    main()