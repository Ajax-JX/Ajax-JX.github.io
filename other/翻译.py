import requests
from bs4 import BeautifulSoup

def locate_li_values(html,a):
    soup = BeautifulSoup(html, 'html.parser')
    li_elements = soup.find_all(a)
    li_values = [li.get_text(strip=True) for li in li_elements]
    return li_values

def translate(a,from1,to):
   url="https://m.youdao.com/translate"
   data={'inputtext': a, 
      'type': from1+'2'+to}
   result=locate_li_values(requests.post(url,data=data).content,"li")[3]
   return result

print(translate("涔濅粰","ZH_CN","EN"))
