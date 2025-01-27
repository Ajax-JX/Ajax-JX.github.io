from bs4 import BeautifulSoup

def locate_element(html, element_name, attrs=None):
    soup = BeautifulSoup(html, 'html.parser')
    element = soup.find(element_name, attrs)
    return element

def locate_li_values(html,a):
    soup = BeautifulSoup(html, 'html.parser')
    li_elements = soup.find_all(a)
    li_values = [li.get_text(strip=True) for li in li_elements]
    return li_values
