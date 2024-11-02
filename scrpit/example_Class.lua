local gg = gg
local info = gg.getTargetInfo()

local off1, off2, ptrType = 0x8, 0x4, 4
if info.x64 then off1, off2, ptrType = 0x10, 0x8, 32 end
local metadata = {}

local pointerSize = (info.x64 and 8 or 4)
local pointerType = (info.x64==true and gg.TYPE_QWORD or gg.TYPE_DWORD)

local libstart=0
local libil2cppXaCdRange
local metadata
local originalResults

local isFieldDump, isMethodDump
local deepSearch = false

function Il2cppModules()
    il2cpp_addr={}
    for i,v in pairs(gg.getRangesList("libil2cpp.so")) do
       --判断真so地址
       gt=gg.getValues({{address=v.start,flags=4}})[1]["value"]
       if v.state=="Xa" and gt==1179403647 then
       table.insert(il2cpp_addr,v.start)
       end
    end
    return il2cpp_addr
 end--获取Il2cpp.so模块地址 注:返回的是一个表



-------------------------Utils Start-------------------------

local searchRanges = {
    ["Ca"] = gg.REGION_C_ALLOC,
    ["A"] = gg.REGION_ANONYMOUS,
    ["O"] = gg.REGION_OTHER,
}

local unsignedFixers = {
    [1] = 0xFF,
    [2] = 0xFFFF,
    [4] = 0xFFFFFFFF,
    [8] = 0xFFFFFFFFFFFFFFFF,
}

local function toUnsigned(value, size)
    if value<0 then
        value = value & unsignedFixers[size]
    end
    return value
end

function tohex(val)
  return string.format("%X", val)
end

function fixAddressForPointer(address, size)
    local remainder = address%size
    if remainder==0 then
        return address
    else
        return address - remainder
    end
end

-------------------------Utils End-------------------------

-------------------------Get Metadata Start-------------------------
--Getting metadata normally
local function fastest()
    return gg.getRangesList("global-metadata.dat")
end

--Checking mscordlib in stringLiteral start
local function faster()
    local metadata = {}
    local allRanges = gg.getRangesList()
    local stringOffset = {} --0x18 of metadata, stringOffset
    local strStart = {}
    
    for i, v in ipairs(allRanges) do
        stringOffset[i] = {address=v.start+0x18, flags=gg.TYPE_DWORD}
    end
    stringOffset = gg.getValues(stringOffset)
    
    for i, v in ipairs(allRanges) do
        strStart[i] = {address=v.start+stringOffset[i].value, flags=gg.TYPE_DWORD}
    end
    strStart = gg.getValues(strStart)
    
    for i, v in ipairs(strStart) do
        --Every string table starts with mscorlib.dll in global-metadata.dat
        --So, if the first 4 bytes are "m(0x6D) s(0x73) c(0x63) o(0x6F)"
        if v.value==0x6F63736D then return {allRanges[i]} end
    end
    return {}
end

--Finding get_fieldOfView in Ca, A, O
local function fast()
    local searchMemoryRange = {
        gg.REGION_C_ALLOC,
        gg.REGION_ANONYMOUS,
        gg.REGION_OTHER,
        gg.REGION_C_HEAP,
    } --add regions where you want to search.
    
    --if you want to search all regions, use following value -1.
    --[[
    local searchMemoryRange = {
        -1,
    }
    --]]
    gg.clearResults()
    for i, v in ipairs(searchMemoryRange) do
        gg.setRanges(v)
        gg.searchNumber("h 00 67 65 74 5F 66 69 65 6C 64 4F 66 56 69 65 77 00", gg.TYPE_BYTE, false, gg.SIGH_EQUAL, 0, -1, 1)
        local res = gg.getResults(gg.getResultsCount())
        gg.clearResults()
        if #res>0 then
            for ii, vv in ipairs(gg.getRangesList()) do
                if res[1].address < vv["end"] and res[1].address > vv["start"] then
                    return {vv}
                end
            end
        end
    end
    return {}
end

function get_metadata()
    local findingMethods = {
        [1] = fastest, --Getting metadata normally
        [2] = faster, --checking mscordlib in stringLiteral
        [3] = fast, --Finding get_fieldOfView in Ca, A, O
    }
    local metadata = {}
    
    for i=1, 3 do
        metadata = findingMethods[i]()
        if #metadata>0 then return metadata end
    end
    return {}
end
-------------------------Get Metadata End-------------------------

function getMainLib_Xa_Cd_Region()
    local packageName = info.packageName
    local libil2cppRanges = gg.getRangesList(packageName=="com.mobile.legends" and "liblogic.so" or "libil2cpp.so")
    if #libil2cppRanges==0 then return {} end
    local XaCdRange = {
        ["start"] = 0,
        ["end"] = 0,
    }
    for i, v in ipairs(libil2cppRanges) do
        local elfHeader = {
            ["magicValue"] = {address=v["start"], flags=gg.TYPE_DWORD},
            ["e_phoff"] = {address=v["start"]+(info.x64 and 0x20 or 0x1C), flags=gg.TYPE_WORD},
            ["e_phnum"] = {address=v["start"]+(info.x64 and 0x38 or 0x2C), flags=gg.TYPE_WORD},
        }
        elfHeader = gg.getValues(elfHeader)
        if elfHeader["magicValue"].value==0x464C457F and v.type:sub(3,3)=="x" then
            local PHstart = v["start"] + elfHeader["e_phoff"].value
            local PHcount = elfHeader["e_phnum"].value
            for index=1, PHcount do
                local offsetDiff =  (index-1)*(info.x64 and 0x38 or 0x20)
                local programHeader = {
                    ["p_type"] = {address = PHstart + offsetDiff, flags = gg.TYPE_DWORD},
                    ["p_vaddr"] = {address = PHstart + offsetDiff + (info.x64 and 0x10 or 0x8), flags = pointerType},
                    ["p_filesz"] = {address = PHstart + offsetDiff + (info.x64 and 0x20 or 0x10), flags = pointerType},
                    ["p_memsz"] ={address = PHstart + offsetDiff + (info.x64 and 0x28 or 0x14), flags = pointerType},
                    ["p_flags"] = {address = PHstart + offsetDiff + (info.x64 and 0x4 or 0x18), flags = gg.TYPE_DWORD},
                }
                programHeader = gg.getValues(programHeader)
                local programType = programHeader["p_type"].value
                local virtualAddr = programHeader["p_vaddr"].value
                local fileSize = programHeader["p_filesz"].value
                local virtualSize = programHeader["p_memsz"].value
                local programFlags = programHeader["p_flags"].value
                if programType==1 then
                    if programFlags==5 then
                        if libstart==0 then
                            libstart = v.start
                            XaCdRange.start = v.start
                        end
                    end
                    if programFlags==6 and fileSize<virtualSize then
                        XaCdRange["end"] = XaCdRange["start"] + virtualAddr + fileSize
                    end
                end
            end
        end
    end
    return XaCdRange
end


function getName(addr)
    local str = ""
    local t = {}
    for i=1, 128 do
        t[i] = {address=addr+(i-1), flags=gg.TYPE_BYTE}
    end
    t = gg.getValues(t)
    
    for i, v in ipairs(t) do
        if v.value==0 then break end
        if v.value<0 then return "" end
        str = str..string.char(v.value&0xFF)
    end
    return str
end

function dumpFields(possibleThings)
    menu_fields={}
    for i=1, #possibleThings, 4 do
        local fieldNamePtr = toUnsigned(possibleThings[i+1].value, pointerSize)
        local fieldTypePtr = toUnsigned(possibleThings[i+2].value, pointerSize)
        local field_offset = possibleThings[i+3].value
        
        if (deepSearch or (fieldNamePtr<metadata[1]["end"] and fieldNamePtr>metadata[1]["start"])) and (fieldTypePtr<libil2cppXaCdRange["end"] and fieldTypePtr>libil2cppXaCdRange["start"]) and field_offset>=0 then
            menu_fields[getName(fieldNamePtr)]=field_offset
        end       
    end
    return menu_fields
end

function dumpMethods(possibleThings)
    menu_methods={}
    for i=1, #possibleThings, 4 do
        local functionPtr = toUnsigned(possibleThings[i].value, pointerSize)
        local invokePtr = toUnsigned(possibleThings[i+1].value, pointerSize)
        local methodNamePtr = toUnsigned(possibleThings[i+2].value, pointerSize)
        --local methodTypePtr = toUnsigned(possibleThings[i+3].value, pointerSize)
        
        if (functionPtr<libil2cppXaCdRange["end"] and functionPtr>libil2cppXaCdRange["start"]) and (invokePtr<libil2cppXaCdRange["end"] and invokePtr>libil2cppXaCdRange["start"]) and (deepSearch or (methodNamePtr<metadata[1]["end"] and methodNamePtr>metadata[1]["start"])) then -- and (methodTypePtr<libil2cppXaCdRange["end"] and methodTypePtr>libil2cppXaCdRange["start"]) then
            menu_methods[getName(methodNamePtr)]=functionPtr-libstart     
        end
    end
end

function Dump(class_parent)
    local selectedRange_shortname = gg.getValuesRange(class_parent)[1]
    gg.setRanges(searchRanges[selectedRange_shortname])
    gg.clearResults()
    gg.searchNumber(class_parent[1].address, pointerType)
    local res = gg.getResults(gg.getResultsCount())
    gg.clearResults()
    
    local all = {}
    local fields = {}
    local methods = {}
    
    for i, v in ipairs(res) do
        all[#all+1] = {address=v.address - (pointerSize*3), flags=pointerType} --function pointer
        all[#all+1] = {address=v.address - (pointerSize*2), flags=pointerType} --invoke function pointer or field name pointer
        all[#all+1] = {address=v.address - (pointerSize*1), flags=pointerType} --function name pointer or field type pointer
        all[#all+1] = {address=v.address + pointerSize, flags=gg.TYPE_DWORD} --function type pointer or field offset
    end
    all = gg.getValues(all)
    
    if isFieldDump then dumpFields(all) end
    if isMethodDump then dumpMethods(all) end
    gg.loadResults(originalResults)
end

function isSameRegion(one, two)
    if not info.x64 then one=one&0xffffffff two=two&0xffffffff end
    local a=gg.getRangesList()
    for i, v in ipairs(a) do
      if one>=v.start and two<v['end'] then
        return true else return false
      end
    end
  end
  
  function getCorrectClassname(tab)
    local t={}
    local temp = {}
    for i, v in ipairs(tab) do
      temp[#temp+1], temp[#temp+2] = {address=v.address-1, flags=1}, {address=v.address+v.strLen, flags=1}
    end
    temp = gg.getValues(temp)
    for i=1, #temp, 2 do
      if temp[i].value==0 and temp[i+1].value==0 then table.insert(t, tab[(i+1)/2]) end
    end
    return t
  end
  
  function is_already_in_table(val, tab)
    for i, v in ipairs(tab) do
      if val==v.address then return true end
    end
    return false
  end
  
  function getField(Name,Offset,SJLX)
    local offForField = 0x8
    if info.x64 then offForField = 0x10 end 
    gg.clearResults()
    gg.setRanges(-2080896)
    gg.searchNumber(':'..Name, 4, false, gg.SIGH_EQUAL, metadata[1].start, metadata[1]['end'])
    local r = gg.getResults(gg.getResultsCount())
    gg.clearResults()
    if #r==0 then return gg.alert('Not found class name\n找不到类名') end
    
    local count = #r/#Name
    local t={}
    for i=1, count do
      local index = ((i-1)*#Name)+1
      r[index].strLen = #Name
      table.insert(t, r[index])
    end
    local a = getCorrectClassname(t)
    if #a==0 then return gg.alert('Not found class name\n找不到类名') end
    --check Ca addresses
    gg.setRanges(-2080892)
    gg.loadResults(a)
    gg.searchPointer(0)
    local r = gg.getResults(gg.getResultsCount())
    local t = {}
    for i, v in ipairs(r) do
      local a = {{address=v.address-off1, flags=1}, {address=v.address+off2, flags=ptrType}}
      a = gg.getValues(a)
      if not info.x64 then a[2].value=a[2].value&0xffffffff end
      if a[2].value>=metadata[1].start and a[2].value<metadata[1]['end'] then table.insert(t, a[1]) end
    end
    
    gg.setRanges(32)
    gg.loadResults(t)
    gg.searchPointer(0)
    gg.loadResults(gg.getResults(gg.getResultsCount()))
    gg.searchPointer(0)
    local r = gg.getResults(gg.getResultsCount())
    local t = {}
    for i, v in ipairs(r) do
      if not is_already_in_table(v.value, t) then table.insert(t, {address=v.value+Offset, flags=SJLX}) end
    end
    if #t==0 then return gg.alert('not found. may be this class is not allocated yet into memory.\n没有找到，可能这个类还没有分配到内存中。') end
    gg.loadResults(t)
    tableA={}
    resultA=gg.getResults(150)
    for p,l in pairs(resultA) do
       table.insert(tableA,l.address)
    end
    gg.clearResults()
   return tableA
  end
  
  function LMss(LM,PY,SJLX)
    local a = gg.getFile()..'.cfg'
    local file = loadfile(a)
    local t = nil
    local pkg = info.packageName
    if not file then t={} else t=file() end
    
    ::here::
    local name_offset = t[pkg]
    if not name_offset then name_offset = {'PlayerScript', '0x4'} end
    
    local str = {}
    str[1]=LM
    str[2]=tostring(PY)
    if not str then return end
    if str[1]=='' then gg.alert('请输入类名！！') goto here end
    if str[2]=='' then gg.alert('请输入偏移量！！') goto here end
    
    if tostring(str[2])~='0' and tostring(str[2])~='0x0' and not tonumber(str[2]) then gg.alert('Error in offset. Put correct one.\n偏移量输入错误。请填写正确的。\nFor example,\n例如：\n\n0x1c --for hex offset\n50 --for decimal offset') goto here end
    str[2] = '0x'..tohex(str[2])
    t[pkg] = str
    str[2] = tonumber(tostring(str[2])) 
    local available = {}
    return getField(str[1], str[2], SJLX,XGNR)
  end
  
  metadata = get_metadata()
  if not metadata then return gg.alert('找不到metadata') end

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
 
 function Class_Search(ClassName,FieldOffset,Type)
    gg.clearResults()
    gg.setRanges(-2080896)
    gg.searchNumber(":"..ClassName,1)
    first_letter=gg.getResults(1)[1].value
    gg.searchNumber(first_letter,1)
    local t={}
    for i,v in pairs(GetAllResults()) do
       gg.setRanges(-2080892)--Ca内存
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

function build(addr,type)
    gg.loadResults({{address=addr,flags=type}})
    local menu={}
    libil2cppXaCdRange = getMainLib_Xa_Cd_Region()
    if libstart==0 then print("未找到libil2cpp.so 如果游戏被拆分 请反拆分它") end
    metadata = get_metadata()
    if #metadata==0 then return print("未找到metadata") end
    originalResults = gg.getResults(gg.getResultsCount()) --checking results in search list(tab)
    if #originalResults==0 then return print("在搜索列表中加载您的地址") end
    
    
    if not menu then return end
    local off_range = 10000
    isFieldDump = true
    isMethodDump = true
    deepSearch = false
    
    for i, v in ipairs(originalResults) do --loop to check every addresses in search list
        local found = false
        local fixedPointer = fixAddressForPointer(v.address, pointerSize)
        table.insert(menu,i..". 地址 0x"..tohex(v.address))
        local addrs = {} --
        for off=0, off_range, pointerSize do --loop to get values of addresses to check class parent pointer
            addrs[#addrs+1] = {address = fixedPointer - off, flags = pointerType}
        end
        addrs = gg.getValues(addrs)
        
        local parentPtr = {}
        local namespacePtr = {}
        local classnamePtr = {}
        
        
        for i_, v_ in ipairs(addrs) do
            parentPtr[i_] = {address = v_.value, flags = pointerType}
            classnamePtr[i_] = {address = v_.value + (pointerSize*2), flags = pointerType}
            namespacePtr[i_] = {address = v_.value + (pointerSize*3), flags = pointerType}
        end
        parentPtr, classnamePtr, namespacePtr = gg.getValues(parentPtr), gg.getValues(classnamePtr), gg.getValues(namespacePtr)
        
        for i_, v_ in ipairs(parentPtr) do
            classnamePtr[i_].value = toUnsigned(classnamePtr[i_].value, pointerSize)
            namespacePtr[i_].value = toUnsigned(namespacePtr[i_].value, pointerSize)
            
            if deepSearch==true or (namespacePtr[i_].value>metadata[1].start and namespacePtr[i_].value<metadata[1]["end"]) then
                local tmp_class_name = getName(classnamePtr[i_].value)
                if tmp_class_name~="" then
                    table.insert(menu,"命名空间:"..getName(namespacePtr[i_].value))
                    table.insert(menu,"类名:"..tmp_class_name)
                    table.insert(menu,tohex(v.address - addrs[i_].address))
                    if isFieldDump or isMethodDump then
                        Dump({parentPtr[i_]})
                    end
                    print(string.rep("=", 30))
                    found = true
                    break
                end
            end
        end
        if found==false then print("无法获取类名 可能偏移太短") gg.alert("无法获取类名 可能偏移太短")  end
    end
    
    return menu
end

function Parsing_class(className,type,FieldName,MethodName)
   if className:find("%[%]") then
      return "不支持数组,请用Class_Search()函数"
   end
   if FieldName ~= "" then
      local start=LMss(className,0x4,type)
      build(start[1],type)
      offset=menu_fields[FieldName]
      addr={}
      for i,v in pairs(start) do
         table.insert(addr,v-0x4+offset)
      end
      return addr
   end
   if FieldName =="" and MethodName~="" then
      lib=Il2cppModules()[1]
      local start=LMss(className,0x4,type)
      build(start[1],type)
      offset=menu_methods[MethodName]
      return lib+offset
   end
end
