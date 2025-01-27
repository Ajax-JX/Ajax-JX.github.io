


require 'LuaWebView[优化]'

function LeoPackage ( tab_view , textView )
	local viewTab = { }
	for k , v in pairs ( tab_view ) do
		if v [ 2 ] == "Switch" then
			viewTab [ # viewTab + 1 ] = { text = v [ 1 ] , isControl = v [ 2 ] , open = v [ 3 ] , close = v [ 4 ] , textColor = v [ 5 ] or nil , wallColor = v [ 6 ] or nil }
		elseif v [ 2 ] == "Button" then
			if type ( v [ 4 ] ) == "string" and v [ 4 ] : sub ( 1 , 2 ) == "0x" then
				viewTab [ # viewTab + 1 ] = { text = v [ 1 ] , isControl = v [ 2 ] , clickEvent = v [ 3 ] , textColor = v [ 4 ] or nil , wallColor = v [ 5 ] or nil , meun = v [ 7 ] }
			else
				viewTab [ # viewTab + 1 ] = { text = v [ 1 ] , isControl = v [ 2 ] , clickEvent = v [ 3 ] , clickLongEvent = v [ 4 ] , textColor = v [ 5 ] or nil , wallColor = v [ 6 ] or nil }
			end
		end
	end
	gg.setVisible ( false )
	setUi ( viewTab )

end






















--[[

共有④种创建新页的组件

1.form["设置主布局"] 顾名思义就是设置新页的各项属性 
传入表{
title
main
back
PageID
subMeun
}
2.form["返回事件"] 顾名思义给新页添加一个返回事件 (传入返回ID,当前页变量,目标返回页变量,目标返回页ID)
3.form["移动事件"] 顾名思义给新页添加一个移动事件(传入当前页变量,传入main代表的ID)
4.form["添加控件"] 顾名思义给新创建的页里添加新的控件(传入目标添加控件的页的变量,传入二维表)




]]

Nnew = form [ "设置主布局" ] ( { title = "测试页1" , main = "Page_one" , back = "FH" , PageID = "page_one" , subMeun = "sub_one" } )
form [ "返回事件" ] ( FH , Nnew , meun_second , mmm )
form [ "添加控件" ] ( second , { { "测试" , function ( )
				window.removeView ( meun_second )
				zoom_animation ( sub_one )
				zoom_startanimation ( )
				window.addView ( Nnew , mainLayoutParams )
			end

		} } )
form [ "添加控件" ] ( second , { { "测试2" , function ( )
				window.removeView ( meun_second )
				zoom_animation ( sub_one )
				zoom_startanimation ( )
				window.addView ( Nnew , mainLayoutParams )
			end

		} } )

-- toast.setStyle("")
-- print(toast.delay("ccc"))
-- print(toast.white("bbb"))

LeoPackage ( { { "异常捕获" , "Button" , 
			function ( )
            error("异常异常异常")
				-- 	gg.alert ( "cc" )
			end

		} } )



--[[
    1.第一次进入脚本会加载一个用户须知公告
        ]]
        
        
