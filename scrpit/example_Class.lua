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

local gg = gg
local info = gg.getTargetInfo()
local off1, off2, ptrType = 0x8, 0x4, 4
if info.x64 then off1, off2, ptrType = 0x10, 0x8, 32 end
local metadata = {}

function tohex(val)
  return string.format('%x', val)
end

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

local function get_metadata()
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
  gg.setVisible(false)
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

local function LMss(LM,PY,SJLX)
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
------------以上是配置，不懂勿动！

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
