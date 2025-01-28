if gg.getTargetInfo().x64==false or nil then
    gg.alert("本脚本不适配当前系统框架哦~") os.exit() end
    function GetAllResults()
       return gg.getResults(gg.getResultsCount())
    end
    
    function modeOfTable(t)
        local countTable = {}
        local maxCount = 0
        local modeValue = nil
        -- 计算每个元素出现的次数
        for _, v in ipairs(t) do
            if countTable[v] then
                countTable[v] = countTable[v] + 1
            else
                countTable[v] = 1
            end
            -- 更新出现次数最多的元素
            if countTable[v] > maxCount then
                maxCount = countTable[v]
                modeValue = v
            end
        end
        return {modeValue,maxCount}
    end--返回的[1]是出现最多的值,[2]为最多的值出现的次数
    
    function GetPointsTo(addr,isNumber)--获取指向
       Get=gg.getValues({{address=addr,flags=32}})[1]
       Hex=string.format("%x",Get.value)
       if isNumber==true then 
       return tonumber(Hex,16)--返回地址十进制
       end
       if not isNumber or isNumber==false then 
       return Hex
       end
    end
    
    function Class_LocatingClassName(Addr,MaxOffset)
    local list={}
    local str={}
       if not MaxOffset then MaxOffset=1000 end
       gg.clearResults()
       gg.setRanges(36)--A加Ca
       gg.loadResults({[1]={address=Addr,flags=32}})
       gg.searchPointer(MaxOffset)
       if gg.getResultsCount()==0 then print("没搜索到呢~") end
       for i,v in pairs(GetAllResults()) do
          addr=v.address
          Pointer=GetPointsTo(addr,true)--字段指针
          table.insert(list,Pointer)
       end
       Pointer=modeOfTable(list)[1]--确定字段指针
       ClassPointer=GetPointsTo(Pointer,true)--类名指针
       ClassStringPointer=ClassPointer+0x10--类名字符串指针
       StringHeader=GetPointsTo(ClassStringPointer,true)--类名字符串起始头
       --开始遍历类名
       py=-0x1
       for x=1,1024 do
          py=py+0x1
          Value=gg.getValues({{address=StringHeader+py,flags=1}})[1].value
          if Value==0 then break end
          if Value < 0 then break end
          if Value > 255 then break end
          string=string.char(Value)
          table.insert(str,string)
       end
       str=table.concat(str,"")
       gg.clearResults()
       return str
    end--反查值的类名
    
    function Class_Search(ClassName,FieldOffset,isSearchWithBrackets,Type)
       gg.clearResults()
       gg.setRanges(-2080892)
       gg.searchNumber(":"..ClassName,1)
       first_letter=gg.getResults(1)[1].value
       gg.searchNumber(first_letter,1)
       local t={}
       for i,v in pairs(GetAllResults()) do
          if isSearchWithBrackets==true then ranges=-2080892 end
          if not isSearchWithBrackets or isSearchWithBrackets==false then ranges=4 end
          gg.setRanges(ranges)--Ca内存
          gg.loadResults({[1]={address=v.address,flags=1}})
          gg.searchPointer(0)
          if gg.getResultsCount()~=0 then table.insert(t,v.address) end
       end--取有结果的Byte
       ClassPointer={}
       for x,y in pairs(t) do
          gg.loadResults({[1]={address=y,flags=1}})
          gg.searchPointer(0)
          ClassStringPointer=GetAllResults()
          for a,b in pairs(ClassStringPointer) do
             if gg.getValues({{address=b.address-0x10,flags=4}})[1].value==0 then break end
             table.insert(ClassPointer,b.address-0x10)
          end
       end
       list={}
       for c,d in pairs(ClassPointer) do
          gg.setRanges(32)--设置A
          gg.loadResults({[1]={address=d,flags=32}})
          gg.searchPointer(0)
          gg.loadResults(GetAllResults())
          gg.searchPointer(0)
          for e,f in pairs(GetAllResults()) do
             f=f.value+FieldOffset--这个value就是指向的地址
             table.insert(list,f)
          end
       end
       gg.clearResults()
       return list
    end--返回一个值的表

    function GetAllResults()
        return gg.getResults(gg.getResultsCount())
     end
     function gv(addr,lx)
        return gg.getValues({{address=addr,flags=lx}})[1].value
     end
     function getMaxValue(tbl)
         local max = tbl[1]
         for _, v in ipairs(tbl) do
             if v > max then
                 max = v
             end
         end
         return max
     end
     function FeatureCode(main_table,Offset)--主表内嵌套其他副表
     if not Offset then Offset=0 end
     results={}
     gg.clearResults()
        main_number=main_table[1][1]
        main_flags=main_table[1][2]
        main_ranges=main_table[1][3]
        gg.setRanges(main_ranges)
        gg.searchNumber(main_number,main_flags)
        for i,v in pairs(GetAllResults()) do
           v=v.address
           for x,y in pairs(main_table) do
              if x ~= 1 then
                Vice_value=y[1]
                Vice_flags=y[2]
                Vice_offset=y[3]
                if gv(v+Vice_offset,Vice_flags)==Vice_value then
                   table.insert(results,v+Offset)
                   break
                end
              end
           end
        end
        gg.clearResults()
        return results
     end
     function FeatureCodeGroup(main_table,Offset)--主表内嵌套其他副表
     if not Offset then Offset=0 end
     results={}
     context={}
     gg.clearResults()
        main_number=main_table[1][1]
        main_flags=main_table[1][2]
        main_ranges=main_table[1][3]
        gg.setRanges(main_ranges)
        for i,v in pairs(main_table) do
           Vice_value=v[1]
           Vice_flags=v[2]
           if Vice_flags==4 then Vice_flags="D" end
           if Vice_flags==127 then Vice_flags="A" end
           if Vice_flags==1 then Vice_flags="B" end
           if Vice_flags==64 then Vice_flags="E" end
           if Vice_flags==16 then Vice_flags="F" end
           if Vice_flags==32 then Vice_flags="Q" end
           if Vice_flags==2 then Vice_flags="W" end
           if Vice_flags==8 then Vice_flags="X" end
           table.insert(context,Vice_value..Vice_flags)
           if i ~= #main_table then
              table.insert(context,";")
           else
              table.insert(context,":")
           end
        end--列出搜索内容  
        local a={}
        for i,v in pairs(main_table) do
           Vice_offset=v[3]
           if Vice_offset <= 0 then Vice_offset=-Vice_offset end
           if i ~= 1 then
             table.insert(a,Vice_offset)
           end
        end
        max=getMaxValue(a)
        identifier=1+max
        table.insert(context,identifier)
        group=table.concat(context,"")
        
        gg.searchNumber(group)
        gg.searchNumber(main_table[1][1],main_table[1][2])
        for i,v in pairs(GetAllResults()) do
           v=v.address
           for x,y in pairs(main_table) do
              if x ~= 1 then
                Vice_value=y[1]
                Vice_flags=y[2]
                Vice_offset=y[3]
                if gv(v+Vice_offset,Vice_flags)==Vice_value then
                   table.insert(results,v+Offset)
                   break
                end
              end
           end
        end
        gg.clearResults()
        return results
     end
     function PreferentialSeach(main_table,Offset)
        gg.clearResults()
        gg.searchNumber(main_table[1][1],main_table[1][2])--搜索主特征码取结果数量
        if gg.getResultsCount() < 500 then
           return FeatureCode(main_table,Offset)
        else
           return FeatureCodeGroup(main_table,Offset)
        end
     end

function own(id,valu)
    gg.clearResults()
    a=Class_Search("Byte[]",0x20,true,4)
    k={}
    for i,v in pairs(a) do
        if gg.getValues({{address=v,flags=4}})[1].value==id then
           table.insert(k,{address=v,flags=4,gg.getValues({{address=v,flags=4}})[1].value})
        end
    end
    gg.clearResults()
    gg.loadResults(k)
    local ph=gg.getResults(gg.getResultsCount())
    gg.addListItems(ph)
    gg.editAll(valu,4)
    gg.clearResults()
end

function others(id,valu)
    gg.clearResults()
    gg.setRanges(32)
    gg.searchNumber(id..";0;"..id..";0;0;-1;-1:29",4)
    gg.searchNumber(id,4)
    local ph=gg.getResults(gg.getResultsCount())
    gg.addListItems(ph)
    gg.editAll(valu,4)
    gg.clearResults()
end

function shijiao()
    A={
        {982105859,4,32},
        {1065353216,4,-0xC}
        }
        B=FeatureCode(A,0x40)
        return {B[1],B[1]-0x4,B[1]-0x8}
end