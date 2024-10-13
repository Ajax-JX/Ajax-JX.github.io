local url="https://ajax-jx.github.io/scrpit/example_Class.lua"
local request=gg.makeRequest(url).content
--基础配置获取


t={"添加功能","生成"}
functions={}
y=gg.prompt({"文件名[别写后缀名]"},{},{"text"})

function menu_()
   menu=gg.choice(t,#t+1,"something")
   if menu==1 then
      p=gg.prompt({"名称","类名","偏移","加载","类型"},{},{"text","text","text","checkbox","number"})
      table.insert(t,p[1])
      if p[4]==false then
         r=gg.prompt({"修改值"})
         functions[#t]={}
         functions[#t]["name"]=p[1]
         functions[#t]["class"]=p[2]
         functions[#t]["offset"]=p[3]
         if p[2]:find("%[%]") then
            way="Class_Search"
         else
            way="LMss"
         end
         functions[#t]["function"]="\n\nlist="..way.."("..'"'..p[2]..'"'..","..p[3]..","..p[5]..")\nt={}\nfor i,v in pairs(list) do \n   gg.setValues({{address=v,flags="..p[5]..",value="..r[1].."}})\nend\n\ngg.toast(".."'"..p[1].."已执行".."'"..")"
      end
      if p[4]==true then
         functions[#t]={}
         functions[#t]["name"]=p[1]
         functions[#t]["class"]=p[2]
         functions[#t]["offset"]=p[3]
         if p[2]:find("%[%]") then
            way1="Class_Search"
         else
            way1="LMss"
         end
         functions[#t]["function"]="\n\nlist="..way1.."("..'"'..p[2]..'"'..","..p[3]..","..p[5]..")\nt={}\nfor i,v in pairs(list) do \n   example={address=v,flags=4,value=gg.getValues({{address=v,flags=4}})[1].value}\n   table.insert(t,example)\nend\ngg.loadResults(t)\ngg.toast(".."'"..p[1].."已执行".."'"..")"
      end
   end
   if menu==2 and #t > 2 then
      io.open(y[1]..".lua","w"):write(request):close()
      for i,v in pairs(functions) do
         io.open(y[1]..".lua","a+"):write(v["function"]):close()
      end
      os.exit()
   end
end

while true do
   menu_()
end
