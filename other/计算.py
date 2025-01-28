
def create(t):
   for item in t:
   	a=item.strip().split('|')[1]
   	print(a)
create(["|1+2|"])
    
