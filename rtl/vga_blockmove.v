
module vga_blockmove(
    input           sys_clk,        //系统时钟
    input           sys_rst_n,      //复位信号
	 //左右按键
	 input		[3:0] KEY,				//按键输入信号
    //VGA接口                          
    output          vga_hs,         //行同步信号
    output          vga_vs,         //场同步信号
    //output  [11:0]  vga_rgb         //红绿蓝三原色输出 
	 output    [4:0]      vga_r,
	 output    [5:0]      vga_g,
	 output    [4:0]      vga_b
    ); 

//wire define
wire         vga_clk_w;             //PLL分频得到25Mhz时钟
wire         locked_w;              //PLL输出稳定信号
wire         rst_n_w;               //内部复位信号
wire [11:0]  pixel_data_w;          //像素点数据
wire [ 9:0]  pixel_xpos_w;          //像素点横坐标
wire [ 9:0]  pixel_ypos_w;          //像素点纵坐标    
wire [11:0] vga_rgb;
//*****************************************************
//**                    main 
//***************************************************** 
//待PLL输出稳定之后，停止复位
assign rst_n_w = sys_rst_n && locked_w;
assign vga_r={vga_rgb[11:8],1'b1};
assign vga_g={vga_rgb[7:4],2'b11};
assign vga_b={vga_rgb[3:0],1'b1};
   
vga_pll	u_vga_pll(                  //时钟分频模块
	.inclk0         (sys_clk),    
	.areset         (~sys_rst_n), 
    
	.c0             (vga_clk_w),      //VGA时钟 25M
	.locked         (locked_w)
	); 

vga_driver u_vga_driver(
    .vga_clk        (vga_clk_w),    
    .sys_rst_n      (rst_n_w),  
	 
    .vga_hs         (vga_hs),       
    .vga_vs         (vga_vs),       
    .vga_rgb        (vga_rgb),      
    
    .pixel_data     (pixel_data_w), 
    .pixel_xpos     (pixel_xpos_w), 
    .pixel_ypos     (pixel_ypos_w)
    ); 
    
vga_display u_vga_display(
    .vga_clk        (vga_clk_w),
    .sys_rst_n      (rst_n_w),
	 
	 .key 				(KEY),		//按键
    
    .pixel_xpos     (pixel_xpos_w),
    .pixel_ypos     (pixel_ypos_w),
    .pixel_data     (pixel_data_w)
    );
	      
endmodule 