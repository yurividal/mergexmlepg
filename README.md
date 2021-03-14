## XML EPG MERGER

Bash Script that runs on Linux to merge 2 or more xml epg files.
Also supports creation of dummy epg into the merge.

**Requires XMLTV installed**
```
sudo apt install xmltv
```

## How To Use
* Fill in the variables with the links to the lists that you want to merge.
* Script supports direct xml or compacted .gz files.
* Execute the script (manually or as a cron, to automate it).
* Output file will be called "merged.xmltv"
* xml lists further down on the list will replace any previous ones in case of overlaping programmes. So, the most complete (or reliable) list should always be on the bottom of the list.
* If you dont want to generate a dummy, simply comment out line 135
* For a better understanding of the dummy epg, see [this repo](https://github.com/yurividal/dummyepgxml).
