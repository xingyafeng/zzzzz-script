import json
import sys

def work(json_path, output_path):
    f = open(json_path)
    info_dic = json.load(f)
    result_dic = {}
    for key in info_dic:
        dic = info_dic[key]
        path = dic['path']
        #     if isinstance(path,list) and len(path)>1:
        #         print(key)
        module_name = dic['module_name']
        dependencies = dic['dependencies']
        installed = dic['installed']
        for p in path:
            if 'test' in p.lower():
                continue

            if not p in result_dic:
                result_dic[p] = {'module_name': [], 'dependencies': [], 'installed': []}

            if not 'test' in module_name.lower():
                result_dic[p]['module_name'].append(module_name)

            for d in dependencies:
                if 'out/target/common/obj' in d.lower():
                    continue
                if not 'test' in d.lower():
                    result_dic[p]['dependencies'].append(d)

            for i in installed:
                if not 'test' in i.lower():
                    result_dic[p]['installed'].append(i)

    jsObj = json.dumps(result_dic)

    fileObject = open('result.json', 'w')
    fileObject.write(jsObj)
    fileObject.close()

    f = open(output_path, 'w')
    for key in result_dic:
        # l1 = result_dic[key]['module_name'] + result_dic[key]['dependencies']
        l1 = result_dic[key]['module_name']
        l2 = []
        for i in l1:
            if i not in l2:
                l2.append(i)

        m = map(lambda x: x, l2)
        s1 = ' '.join(m)
        #     print(s1)
        #     break
        s = "{0}:{1}\n".format(key, s1)
        f.write(s)
    f.close()

    f = open('result_installed.txt', 'w')
    for key in result_dic:
        l1 = result_dic[key]['installed'] + result_dic[key]['dependencies']
        l1 = result_dic[key]['installed']
        l2 = []
        for i in l1:
            if i not in l2:
                l2.append(i)

        m = list(map(lambda x: x, l2))
        if len(m) == 0:
            continue
        s1 = ' '.join(m)
        s = "{0}:{1}\n".format(key, s1)
        f.write(s)
    f.close()


if __name__ == '__main__':
    work(sys.argv[1], sys.argv[2])
