import math
import sys

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
    with open(sys.argv[1],'r',encoding='gbk') as fd:
        d1 = fd.readlines()
        d1 = list(map(lambda t:t.strip("\n").split(' '),d1))
    with open(sys.argv[2],'r',encoding='gbk') as fd:
        d2 = fd.readlines()
        d2 = list(map(lambda t:t.strip("\n").split(' '),d2))
    for i in d1:
        best = 0
        idx_name = '第0帧'
        for j in d2:
            v = cos_dis(i,j)
            if v > best:
                best = v
                idx_name = j[0]
        print(i[0],idx_name,best)
