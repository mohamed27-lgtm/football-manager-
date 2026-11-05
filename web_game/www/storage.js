const Storage={

save(key,data){
localStorage.setItem(key,JSON.stringify(data));
},

load(key,def=[]){
const d=localStorage.getItem(key);
return d?JSON.parse(d):def;
},

exists(key){
return localStorage.getItem(key)!==null;
}

};