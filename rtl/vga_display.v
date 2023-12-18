//************显示模块***************************
module vga_display(
    input             vga_clk,                  //VGA驱动时钟
    input             sys_rst_n,                //复位信号
	 
	 input 	   [ 3:0] key,								//按键输入信号
	 
    input      [ 9:0] pixel_xpos,               //像素点横坐标
    input      [ 9:0] pixel_ypos,               //像素点纵坐标    
    output reg [11:0] pixel_data                //像素点数据
    );    

//parameter define    
parameter  H_DISP  = 10'd640;                   //分辨率——行
parameter  V_DISP  = 10'd480;                   //分辨率——列

localparam SIDE_W  = 10'd40;                    //边框宽度
localparam BLOCK_W = 10'd40;                    //方块宽度
localparam muban_W = 10'd80;							//木板宽度
localparam BLUE    = 11'b0000_0000_1111;    //边框颜色 蓝色
localparam WHITE   = 11'b1111_1111_1111;    //背景颜色 白色
localparam BLACK   = 11'b0000_0000_0000;    //方块颜色 黑色

//reg define
reg [ 9:0] block_x;                             //方块左上角横坐标
reg [ 9:0] block_y;                             //方块左上角纵坐标
reg [21:0] div_cnt;                             //时钟分频计数器1
reg [21:0] div_cnt_muban; 								//时钟分频计数器2
reg        h_direct;                            //方块水平移动方向，1：右移，0：左移
reg        v_direct;                            //方块竖直移动方向，1：向下，0：向上
reg [ 9:0] muban_x;										//木板A左上角横坐标
reg [ 9:0] muban_x_B;									//木板B左上角横坐标
reg        game_over = 1'b0;   						//游戏结束标志位
reg        gear = 1'd1;									//速度档位

//wire define   
wire move_en;                                   //方块移动使能信号，频率为100hz
wire muban_move_en;										//木板移动使能信号，频率为50hz

assign move_en = (div_cnt == 22'd250000 - 1'b1) ? 1'b1 : 1'b0;
assign muban_move_en = (div_cnt_muban == 22'd125000 - 1'b1) ? 1'b1 : 1'b0;

//通过对vga驱动时钟计数，实现时钟分频
always @(posedge vga_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)
        div_cnt <= 22'd0;
    else 
	  begin
		if(gear == 1'd1)      				//第一档
       begin  if(div_cnt < 22'd250000 - 1'b1) 			
            div_cnt <= div_cnt + 1'b1;
        else
            div_cnt <= 22'd0;
		 end                    
		else if(gear == 1'd2)
		 begin 
			if(div_cnt < 22'd200000 - 1'b1)//第二档 
            div_cnt <= div_cnt + 1'b1;
         else
            div_cnt <= 22'd0;
		 end
		else if(gear == 1'd3)
		 begin 
			if(div_cnt < 22'd175000 - 1'b1)//第三档 
            div_cnt <= div_cnt + 1'b1;
        else
            div_cnt <= 22'd0;
		 end 
		else if(gear == 1'd4)
		 begin 
			if(div_cnt < 22'd125000 - 1'b1)//第四档 
            div_cnt <= div_cnt + 1'b1;
        else
            div_cnt <= 22'd0;
		 end 
		else if(gear == 1'd5)
		 begin
			if(div_cnt < 22'd100000 - 1'b1)//第五档 
            div_cnt <= div_cnt + 1'b1;
        else
            div_cnt <= 22'd0;
		 end 
		else 
		 begin
			if(div_cnt < 22'd75000 - 1'b1)//第六档 
            div_cnt <= div_cnt + 1'b1;
        else
            div_cnt <= 22'd0;
		 end 
     end
end
//木板的时钟分频
always @(posedge vga_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)
        div_cnt_muban <= 22'd0;
    else begin
        if(div_cnt_muban < 22'd125000 - 1'b1) 
            div_cnt_muban <= div_cnt_muban + 1'b1;
        else
            div_cnt_muban <= 22'd0;                   //计数达5ms后清零
    end
end
//当方块移动到边界时，改变移动方向
always @(posedge vga_clk or negedge sys_rst_n) 
begin         
    if (!sys_rst_n) 
		begin
        h_direct <= 1'b1;                       //方块初始水平向右移动
        v_direct <= 1'b1;                       //方块初始竖直向下移动
		end
    else 
		begin
		  //左右边界反弹********************************************************************************************
        if(block_x == SIDE_W - 1'b1)           //到达左边界时，水平向右
           begin  h_direct <= 1'b1; 
			  if((block_y !== SIDE_W)&&(block_y !== V_DISP - SIDE_W - BLOCK_W ))//若同时不在上下边界
						game_over <= 1'b0;//让游戏继续
			  end
        else                                    //到达右边界时，水平向左
        if(block_x == H_DISP - SIDE_W - BLOCK_W)
           begin  h_direct <= 1'b0;   
			  if((block_y !== SIDE_W)&&(block_y !== V_DISP - SIDE_W - BLOCK_W ))//若同时不在上下边界
						game_over <= 1'b0;//让游戏继续
			  end
		  else
           begin  h_direct <= h_direct;
			  if((block_y !== SIDE_W)&&(block_y !== V_DISP - SIDE_W - BLOCK_W ))//若任何边界都不在时
						game_over <= 1'b0;//让游戏继续
		     end
        //上下边界反弹*******************************************************************************************
        if((block_y == SIDE_W)&&(muban_x_B <= block_x + BLOCK_W)&&(block_x <= muban_x_B + muban_W))//到达上边界且横坐标在木板上，竖直向下
			begin 
				v_direct <= 1'b1;  
				if(gear < 1'd6)
				gear <= gear +1'd1;//档位加一
			end 
		  else	 										   //到达上边界且横坐标不在木板上
		  if((block_y == SIDE_W)&&(!((muban_x_B <= block_x + BLOCK_W)&&(block_x <= muban_x_B + muban_W))))
			begin 
				game_over <= 1'b1;							 //游戏结束   
				h_direct <= 1'b1;                       //方块初始水平向右移动
				v_direct <= 1'b1;                       //方块初始竖直向下移动
				gear <= 1'd1;									 //回到初始速度
			end 
			//上下分界
        else                                   
        if((block_y == V_DISP - SIDE_W - BLOCK_W)&&(muban_x <= block_x + BLOCK_W)&&(block_x <= muban_x + muban_W))//到达下边界且横坐标在木板上，竖直向下
		     begin
				v_direct <= 1'b0;  
				if(gear < 1'd6)
				gear <= gear + 1'd1;//档位加一
		     end 
		  else	 										       //到达下边界且横坐标不在木板上
		  if((block_y == V_DISP - SIDE_W - BLOCK_W)&&(!((muban_x <= block_x + BLOCK_W)&&(block_x <= muban_x + muban_W))))
			  begin 
				game_over <= 1'b1;						    //游戏结束   
				h_direct <= 1'b1;                       //方块初始水平向右移动
				v_direct <= 1'b1;                       //方块初始竖直向下移动
				gear <= 1'd1;									 //回到初始速度
			  end 
		end
end
//根据按键判断木板移动方向，并改变其横坐标
always @(posedge vga_clk or negedge sys_rst_n) 
begin   
	 if (!sys_rst_n) 
		begin
		  muban_x <= 22'd100;							//木板A初始位置横坐标
		  muban_x_B <= 22'd100;							//木板B初始位置横坐标
		end 
	 else if(muban_move_en)
		begin
		  if((key[1] == 0)&&(muban_x <= H_DISP - SIDE_W - muban_W))
				muban_x <= muban_x + 1'b1; 
		  else if ((key[0] == 0)&&(muban_x >= SIDE_W))
				muban_x <= muban_x - 1'b1; 
		  else 
				muban_x <= muban_x;
				//木板A的移动
		  if((key[3] == 0)&&(muban_x_B <= H_DISP - SIDE_W - muban_W))
				muban_x_B <= muban_x_B + 1'b1; 
		  else if ((key[2] == 0)&&(muban_x_B >= SIDE_W))
				muban_x_B <= muban_x_B - 1'b1; 
		  else 
				muban_x_B <= muban_x_B;
				//木板B的移动
		end
	 else 
		begin 
			if(game_over == 1'b0)
			 begin
				muban_x <= muban_x;
				muban_x_B <= muban_x_B;
			 end
			else
			 begin
				muban_x <= 22'd100;
				muban_x_B <= 22'd100;
			 end
		end
end	
				
//根据方块移动方向，改变其纵横坐标
always @(posedge vga_clk or negedge sys_rst_n) 
begin         
    if (!sys_rst_n) 
		begin
        block_x <= 22'd100;                     //方块初始位置横坐标
        block_y <= 22'd100;                     //方块初始位置纵坐标
		end
    else if(move_en) 
		begin
        if(h_direct) 
            block_x <= block_x + 1'b1;          //方块向右移动
        else
            block_x <= block_x - 1'b1;          //方块向左移动
            
        if(v_direct) 
            block_y <= block_y + 1'b1;          //方块向下移动
        else
            block_y <= block_y - 1'b1;          //方块向上移动
		end
    else 
		begin
		 if(game_over == 1'b0)
		  begin
			block_x <= block_x;
			block_y <= block_y;
		  end
		 else
		  begin
			block_x <= 22'd100;
			block_y <= 22'd100;
		  end
		end
end

//给不同的区域绘制不同的颜色
always @(posedge vga_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n) 
        pixel_data <= BLACK;
    else begin
        if((pixel_xpos < SIDE_W) || (pixel_xpos >= H_DISP - SIDE_W)|| ((pixel_ypos < SIDE_W)&&(pixel_xpos >= muban_x_B)&&(pixel_xpos <= muban_x_B + muban_W))
			 || ((pixel_ypos >= V_DISP - SIDE_W)&&(pixel_xpos >= muban_x)&&(pixel_xpos <= muban_x + muban_W)))// A木板
            pixel_data <= BLUE;                 //绘制边框为蓝色
        else
        if((pixel_xpos >= block_x) && (pixel_xpos < block_x + BLOCK_W)
          && (pixel_ypos >= block_y) && (pixel_ypos < block_y + BLOCK_W))
            pixel_data <= BLACK;                //绘制方块为黑色
        else
            pixel_data <= WHITE;                //绘制背景为白色
    end
end

endmodule
