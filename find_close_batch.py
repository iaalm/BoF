import math
import sys
import re

def dot(x,y):
    return sum(map(lambda a,b:int(a)*int(b),x,y))

def cos_dis(a,b):
    x = a[1:]
    y = b[1:]
    try:
        return dot(x,y)/math.sqrt(dot(x,x)*dot(y,y))
    except ZeroDivisionError:
        return 0


if __name__ == '__main__':
    gnum = re.compile('第(\d*)帧')
    with open(sys.argv[1],'r',encoding='gbk') as fd:
        d1 = fd.readlines()
        d1 = list(map(lambda t:t.strip("\n").split(' '),d1))
    with open(sys.argv[2],'r',encoding='gbk') as fd:
        d2 = fd.readlines()
        d2 = list(map(lambda t:t.strip("\n").split(' '),d2))
    for i in d1:
        i_ix = int(gnum.findall(i[0])[0])
        best = 0
        idx_name = i_ix
        for j in d2:
            j_ix = int(gnum.findall(j[0])[0])
            if abs(i_ix - j_ix) < 8:
                v = cos_dis(i,j)
                if v > best:
                    best = v
                    idx_name = j_ix
        print(i_ix,idx_name)
