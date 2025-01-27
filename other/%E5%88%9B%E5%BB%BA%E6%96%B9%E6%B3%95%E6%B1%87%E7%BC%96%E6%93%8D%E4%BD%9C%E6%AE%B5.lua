function M_write(addr,va,flag)
   gg.setValues({{address=addr,flags=flag,value=va}})
end
function M_GV(addr,flag)
   return gg.getValues({{address=addr,flags=flag}})[1].value
end
function C_MemoryPage()
   return gg.allocatePage(gg.PROT_READ | gg.PROT_WRITE | gg.PROT_EXEC)
end
function Inject_page(method_addr)
   gg.processToggle()
   local Unique_Page=C_MemoryPage()
   local A=M_GV(method_addr,4)
   local B=M_GV(method_addr+0x4,4)
   local C=M_GV(method_addr+0x8,4)
   M_write(method_addr,"~A8 LDR X19, [PC,#0x8]",4)
   M_write(method_addr+0x4,"~A8 BR X19",4)
   M_write(method_addr+0x8,Unique_Page,32)
   ---
   M_write(Unique_Page,A,4)
   M_write(Unique_Page+0x4,B,4)
   M_write(Unique_Page+0x8,C,4)
   M_write(Unique_Page+0xC,"~A8 LDR X19, [PC,#0x8]",4)
   M_write(Unique_Page+0xC+0x4,"~A8 BR X19",4)
   M_write(Unique_Page+0xC+0x8,method_addr+0xC,32)
   return Unique_Page
end
print(string.format("%X",Inject_page(0x705AA64380)))
