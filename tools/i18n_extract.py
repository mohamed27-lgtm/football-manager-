import re,glob,json,sys
AR=re.compile(r'[\u0600-\u06FF]')
def scan(src):
    """yield (start,end,template) for each (merged adjacent) string literal containing Arabic"""
    i=0;n=len(src);lits=[]
    while i<n:
        c=src[i]
        if c=='/' and src[i:i+2]=='//':
            j=src.find('\n',i); i=n if j<0 else j; continue
        if c in '\'"':
            q=c; j=i+1; out=[]
            while j<n and src[j]!=q:
                if src[j]=='\\': out.append(src[j:j+2]); j+=2; continue
                if src[j]=='$':
                    if src[j+1]=='{':
                        d=1;k=j+2
                        while d and k<n:
                            if src[k]=='{':d+=1
                            elif src[k]=='}':d-=1
                            elif src[k] in '\'"':
                                qq=src[k];k+=1
                                while src[k]!=qq:
                                    k+=2 if src[k]=='\\' else 1
                            k+=1
                        out.append('{}');j=k;continue
                    m=re.match(r'\$[A-Za-z_]\w*',src[j:])
                    if m: out.append('{}');j+=m.end();continue
                out.append(src[j]);j+=1
            lits.append((i,j+1,''.join(out)));i=j+1;continue
        i+=1
    # merge adjacent
    res=[];k=0
    while k<len(lits):
        s,e,t=lits[k];k+=1
        while k<len(lits) and src[e:lits[k][0]].strip()=='' :
            t+=lits[k][2];e=lits[k][1];k+=1
        res.append((s,e,t))
    return res
def unesc(t): return t.replace("\\'","'").replace('\\n','\n').replace('\\$','$').replace('\\"','"').replace('\\\\','\\')
if __name__=='__main__':
    keys={}
    for f in sorted(glob.glob('lib/*.dart')):
        if f.endswith('translations.dart'): continue
        for s,e,t in scan(open(f,encoding='utf-8').read()):
            if AR.search(t): keys.setdefault(unesc(t),f)
    json.dump(list(keys),open('tools/i18n_keys.json','w',encoding='utf-8'),ensure_ascii=False,indent=0)
    print(len(keys))
