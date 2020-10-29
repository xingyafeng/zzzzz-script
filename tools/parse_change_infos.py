import os
import sys
import json
import re

def main(filename,branch):
    branch_list=branch.split('@')
    if os.path.isfile(filename):
        changeNumList = []
        with open(filename, 'r') as fp:
            for l in fp:
                changedict=json.loads(l)
                if changedict.has_key('rowCount'):
                    continue
                if changedict.has_key('project'):
                    project = changedict['project']
                if changedict.has_key('branch'):
                    branch = changedict['branch']
                    is_br=False
                    for br in branch_list:
                        if br.strip() == branch.strip():
                            is_br=True
                            break
                    if not is_br:
                        continue
                else:
                    print "KeyError: object has no key 'branch'"
                    sys.exit(1)
                if changedict.has_key('number'):
                    changenumber = bytes(changedict['number'])
                    changeNumList.append(changenumber)
                else:
                    print "KeyError: object has no key 'number'"
                    sys.exit(1)
                if changedict.has_key('currentPatchSet'):
                    if changedict['currentPatchSet'].has_key('number'):
                        patchset = bytes(changedict['currentPatchSet']['number'])
                    else:
                        print "KeyError: 'currentPatchSet' object has no key 'number'"
                        sys.exit(1)
                    if changedict['currentPatchSet'].has_key('revision'):
                        revision = changedict['currentPatchSet']['revision']
                    else:
                        print "KeyError: 'currentPatchSet' object has no key 'revision'"
                        sys.exit(1)
                    if changedict['currentPatchSet'].has_key('ref'):
                        refspec = changedict['currentPatchSet']['ref']
                    else:
                        print "KeyError: 'currentPatchSet' object has no key 'ref'"
                        sys.exit(1)
                else:
                    print "KeyError: object has no key 'currentPatchSet'"
                    sys.exit(1)
                if changedict.has_key('url'):
                    url = changedict['url']
                    m = re.search('10.128.161.209', url)
                    if m:
                        url = 'http://10.129.93.179:8080/#/c/'+project+"/+/"+changenumber
                else:
                    print "KeyError: object has no key 'url'"
                    sys.exit(1)
                fs = open(changenumber, 'w')
                fs.write('project='+project+'\n')
                fs.write('branch='+branch+'\n')
                fs.write('changenumber='+changenumber+'\n')
                fs.write('revision='+revision+'\n')
                fs.write('patchset='+patchset+'\n')
                fs.write('refspec='+refspec+'\n')
                fs.write('url='+url+'\n')
                fs.close()
        changeNum = open('change_number_list.txt', 'w')
        for num in changeNumList:
            changeNum.write(num+'\n')
        changeNum.close()
    else:
        print "No such file or directory: '%s'" % filename
        sys.exit(2)


if __name__ == '__main__':

    main(sys.argv[1],sys.argv[2])
