
def convert_to_dict(stri):
    p={}
    i=stri.strip().split("\n")
    for item in i :
        b=item.strip().split(":")
        p[b[0]]=b[1].lstrip()
    return p


a="""
inputtext: 你好
type: ZH_CN2EN
"""
print(convert_to_dict(a))
