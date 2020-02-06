
`include "vpg.h"

module vpg(
	clk_50,
	reset_n,
	SW,
	mode,
	mode_change,
	vpg_pclk,
	vpg_de,
	vpg_hs,
	vpg_vs,
	vpg_r,
	vpg_g,
	vpg_b
);

input					clk_50;
input					reset_n;
input		[3:0]		mode;
input					mode_change;
input 	[2:0]		SW;
output				vpg_pclk;
output				vpg_de;
output				vpg_hs;
output				vpg_vs;
output	[7:0]		vpg_r;
output	[7:0]		vpg_g;
output	[7:0]		vpg_b;

//=======================================================
//  Signal declarations
//=======================================================
//=============== PLL reconfigure
wire [63:0] reconfig_to_pll, reconfig_from_pll;
wire        gen_clk_locked;
wire [31:0] mgmt_readdata, mgmt_writedata;
wire        mgmt_read, mgmt_write;
wire [5:0]  mgmt_address;
wire [11:00]vertical_end;
wire [11:0]	horizontal_end;
//============= assign timing constant 
reg  [7:0]  vpg_r;
reg  [11:0] h_total, h_sync, h_start, h_end; 
reg  [11:0] v_total, v_sync, v_start, v_end; 
reg  [11:0] v_active_14, v_active_24, v_active_34; 

//initial begin
assign vpg_g=8'd255;
assign vpg_b=8'd255;
//end
//=======================================================
//  Sub-module
//=======================================================
//=============== PLL reconfigure
pll_reconfig u_pll_reconfig (
	.mgmt_clk(clk_50),
	.mgmt_reset(!reset_n),
	.mgmt_readdata(mgmt_readdata),
	.mgmt_waitrequest(),
	.mgmt_read(mgmt_read),
	.mgmt_write(mgmt_write),
	.mgmt_address(mgmt_address),
	.mgmt_writedata(mgmt_writedata),
	.reconfig_to_pll(reconfig_to_pll),
	.reconfig_from_pll(reconfig_from_pll) );

pll u_pll (
	.refclk(clk_50),           
	.rst(!reset_n),              
	.outclk_0(vpg_pclk), 
	.locked(gen_clk_locked),           
	.reconfig_to_pll(reconfig_to_pll),  
	.reconfig_from_pll(reconfig_from_pll) );

pll_controller u_pll_controller (
	.clk(clk_50),
	.reset_n(reset_n),
	.mode(mode),
	.mode_change(mode_change),
	.mgmt_readdata(mgmt_readdata),
	.mgmt_read(mgmt_read),
	.mgmt_write(mgmt_write),
	.mgmt_address(mgmt_address),
	.mgmt_writedata(mgmt_writedata) );

//=============== pattern generator according to vga timing
vga_generator u_vga_generator (                                    
	.clk(vpg_pclk),                
	.reset_n(gen_clk_locked),                                                
	.h_total(h_total),           
	.h_sync(h_sync),           
	.h_start(h_start),             
	.h_end(h_end),                                                    
	.v_total(v_total),           
	.v_sync(v_sync),            
	.v_start(v_start),           
	.v_end(v_end), 
	.v_active_14(v_active_14), 
	.v_active_24(v_active_24), 
	.v_active_34(v_active_34), 
	.vga_hs(vpg_hs),
	.vga_vs(vpg_vs),           
	.vga_de(vpg_de),
	.v_count(vertical_end),
	.h_count(horizontal_end)
	);

//=======================================================
//  Structural coding
//=======================================================
//============= assign timing constant  
//h_total : total - 1
//h_sync : sync - 1
//h_start : sync + back porch - 1 - 2(delay)
//h_end : h_start + active
//v_total : total - 1
//v_sync : sync - 1
//v_start : sync + back porch - 1
//v_end : v_start + active
//v_active_14 : v_start + 1/4 active
//v_active_24 : v_start + 2/4 active
//v_active_34 : v_start + 3/4 active
always @(mode)
begin
	case (mode)
		`VGA_640x480p60: begin //640x480@60 25.175 MHZ
			{h_total, h_sync, h_start, h_end} <= {12'd799, 12'd95, 12'd141, 12'd781}; 
			{v_total, v_sync, v_start, v_end} <= {12'd524, 12'd1, 12'd34, 12'd514}; 
			{v_active_14, v_active_24, v_active_34} <= {12'd154, 12'd274, 12'd394};
		end	
		`MODE_720x480: begin //720x480@60 27MHZ (VIC=3, 480P)
			{h_total, h_sync, h_start, h_end} <= {12'd857, 12'd61, 12'd119, 12'd839}; 
			{v_total, v_sync, v_start, v_end} <= {12'd524, 12'd5, 12'd35, 12'd515}; 
			{v_active_14, v_active_24, v_active_34} <= {12'd155, 12'd275, 12'd395};
		end
		`MODE_1024x768: begin //1024x768@60 65MHZ (XGA)
			{h_total, h_sync, h_start, h_end} <= {12'd1343, 12'd135, 12'd293, 12'd1317}; 
			{v_total, v_sync, v_start, v_end} <= {12'd805, 12'd5, 12'd34, 12'd802}; 
			{v_active_14, v_active_24, v_active_34} <= {12'd226, 12'd418, 12'd610};
		end
		`MODE_1280x1024: begin //1280x1024@60   108MHZ (SXGA)
			{h_total, h_sync, h_start, h_end} <= {12'd1687, 12'd111, 12'd357, 12'd1637}; 
			{v_total, v_sync, v_start, v_end} <= {12'd1065, 12'd2, 12'd40, 12'd1064}; 
			{v_active_14, v_active_24, v_active_34} <= {12'd296, 12'd552, 12'd808};
		end	
		`FHD_1920x1080p60: begin //1920x1080p60 148.5MHZ (1080i)
			{h_total, h_sync, h_start, h_end} <= {12'd2199, 12'd43, 12'd189, 12'd2109}; 
			{v_total, v_sync, v_start, v_end} <= {12'd1124, 12'd4, 12'd40, 12'd1120}; 
			{v_active_14, v_active_24, v_active_34} <= {12'd310, 12'd580, 12'd850};
		end		
		default: begin //1920x1080p60 148.5MHZ (1080i)
			{h_total, h_sync, h_start, h_end} <= {12'd2199, 12'd43, 12'd189, 12'd2109}; 
			{v_total, v_sync, v_start, v_end} <= {12'd1124, 12'd4, 12'd40, 12'd1120}; 
			{v_active_14, v_active_24, v_active_34} <= {12'd310, 12'd580, 12'd850};
		end
	endcase
end
// generacion de patrones
always@(horizontal_end or vertical_end or SW)
begin
	if(SW==3'd1) begin				///HELLO///
		if((horizontal_end>=12'd173) && (horizontal_end<=12'd202) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//h
		 ||(horizontal_end>=12'd243) && (horizontal_end<=12'd273) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//h
		 ||(horizontal_end>=12'd203) && (horizontal_end<=12'd242) && (vertical_end>=12'd259) && (vertical_end<=12'd289)//h
		 ||(horizontal_end>=12'd293) && (horizontal_end<=12'd312) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//E
		 ||(horizontal_end>=12'd313) && (horizontal_end<=12'd393) && (vertical_end>=12'd174) && (vertical_end<=12'd194)//E
		 ||(horizontal_end>=12'd313) && (horizontal_end<=12'd393) && (vertical_end>=12'd265) && (vertical_end<=12'd284)//E
		 ||(horizontal_end>=12'd313) && (horizontal_end<=12'd393) && (vertical_end>=12'd354) && (vertical_end<=12'd373)//E
		 ||(horizontal_end>=12'd413) && (horizontal_end<=12'd432) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//L0
		 ||(horizontal_end>=12'd433) && (horizontal_end<=12'd502) && (vertical_end>=12'd354) && (vertical_end<=12'd373)//L0
		 ||(horizontal_end>=12'd533) && (horizontal_end<=12'd552) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//L1
		 ||(horizontal_end>=12'd553) && (horizontal_end<=12'd623) && (vertical_end>=12'd354) && (vertical_end<=12'd373)//L1
		 ||(horizontal_end>=12'd653) && (horizontal_end<=12'd672) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//O
		 ||(horizontal_end>=12'd733) && (horizontal_end<=12'd752) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//O
		 ||(horizontal_end>=12'd673) && (horizontal_end<=12'd732) && (vertical_end>=12'd174) && (vertical_end<=12'd203)//O
		 ||(horizontal_end>=12'd673) && (horizontal_end<=12'd732) && (vertical_end>=12'd354) && (vertical_end<=12'd373)//O
		 )
			vpg_r<=8'd120;
		else
			vpg_r<=8'd255;
		end
	else if(SW==3'd2) begin			//DEAF//
		if((horizontal_end>=12'd213) && (horizontal_end<=12'd233) && (vertical_end>=12'd295) && (vertical_end<=12'd373)//d
		 ||(horizontal_end>=12'd294) && (horizontal_end<=12'd312) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//d
		 ||(horizontal_end>=12'd233) && (horizontal_end<=12'd293) && (vertical_end>=12'd295) && (vertical_end<=12'd314)//d
		 ||(horizontal_end>=12'd233) && (horizontal_end<=12'd293) && (vertical_end>=12'd354) && (vertical_end<=12'd373)//d
		 ||(horizontal_end>=12'd332) && (horizontal_end<=12'd351) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//E
		 ||(horizontal_end>=12'd352) && (horizontal_end<=12'd431) && (vertical_end>=12'd174) && (vertical_end<=12'd193)//E
		 ||(horizontal_end>=12'd352) && (horizontal_end<=12'd431) && (vertical_end>=12'd264) && (vertical_end<=12'd283)//E
		 ||(horizontal_end>=12'd352) && (horizontal_end<=12'd431) && (vertical_end>=12'd354) && (vertical_end<=12'd373)//E
		 ||(horizontal_end>=12'd450) && (horizontal_end<=12'd469) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//A
		 ||(horizontal_end>=12'd530) && (horizontal_end<=12'd549) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//A
		 ||(horizontal_end>=12'd470) && (horizontal_end<=12'd529) && (vertical_end>=12'd174) && (vertical_end<=12'd193)//A
		 ||(horizontal_end>=12'd470) && (horizontal_end<=12'd529) && (vertical_end>=12'd264) && (vertical_end<=12'd303)//A
		 ||(horizontal_end>=12'd569) && (horizontal_end<=12'd588) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//F 
		 ||(horizontal_end>=12'd589) && (horizontal_end<=12'd668) && (vertical_end>=12'd174) && (vertical_end<=12'd193)//F
		 ||(horizontal_end>=12'd589) && (horizontal_end<=12'd668) && (vertical_end>=12'd232) && (vertical_end<=12'd252)//F
		 )
			vpg_r<=8'd120;
		else
			vpg_r<=8'd255;
		end
	else if(SW==3'd4) begin			//ME//
		if((horizontal_end>=12'd353) && (horizontal_end<=12'd372) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//M
		 ||(horizontal_end>=12'd433) && (horizontal_end<=12'd452) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//M
		 ||(horizontal_end>=12'd373) && (horizontal_end<=12'd432) && (vertical_end>=12'd174) && (vertical_end<=12'd193)//M
		 ||(horizontal_end>=12'd393) && (horizontal_end<=12'd412) && (vertical_end>=12'd194) && (vertical_end<=12'd273)//M
		 ||(horizontal_end>=12'd473) && (horizontal_end<=12'd492) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//E
		 ||(horizontal_end>=12'd493) && (horizontal_end<=12'd572) && (vertical_end>=12'd174) && (vertical_end<=12'd193)//E
		 ||(horizontal_end>=12'd493) && (horizontal_end<=12'd572) && (vertical_end>=12'd265) && (vertical_end<=12'd284)//E
		 ||(horizontal_end>=12'd493) && (horizontal_end<=12'd572) && (vertical_end>=12'd354) && (vertical_end<=12'd373)//E
		 )
			vpg_r<=8'd120;
		else
			vpg_r<=8'd255;
		end
	else if(SW==3'd3) begin		//YOU//
		if((horizontal_end>=12'd294) && (horizontal_end<=12'd313) && (vertical_end>=12'd174) && (vertical_end<=12'd233)//Y
		 ||(horizontal_end>=12'd374) && (horizontal_end<=12'd393) && (vertical_end>=12'd174) && (vertical_end<=12'd233)//Y
		 ||(horizontal_end>=12'd313) && (horizontal_end<=12'd373) && (vertical_end>=12'd204) && (vertical_end<=12'd233)//Y
		 ||(horizontal_end>=12'd334) && (horizontal_end<=12'd353) && (vertical_end>=12'd234) && (vertical_end<=12'd373)//Y
		 ||(horizontal_end>=12'd413) && (horizontal_end<=12'd432) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//O
		 ||(horizontal_end>=12'd433) && (horizontal_end<=12'd492) && (vertical_end>=12'd174) && (vertical_end<=12'd193)//O
		 ||(horizontal_end>=12'd433) && (horizontal_end<=12'd492) && (vertical_end>=12'd354) && (vertical_end<=12'd373)//O
		 ||(horizontal_end>=12'd493) && (horizontal_end<=12'd512) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//O
		 ||(horizontal_end>=12'd532) && (horizontal_end<=12'd551) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//U
		 ||(horizontal_end>=12'd551) && (horizontal_end<=12'd613) && (vertical_end>=12'd354) && (vertical_end<=12'd373)//U
		 ||(horizontal_end>=12'd613) && (horizontal_end<=12'd632) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//U
		 )
			vpg_r<=8'd120;
		else
			vpg_r<=8'd255;
		end
	else if(SW==3'd5) begin		//SIGN//
		if((horizontal_end>=12'd234) && (horizontal_end<=12'd334) && (vertical_end>=12'd174) && (vertical_end<=12'd193)//S
		 ||(horizontal_end>=12'd234) && (horizontal_end<=12'd334) && (vertical_end>=12'd265) && (vertical_end<=12'd284)//S
		 ||(horizontal_end>=12'd234) && (horizontal_end<=12'd334) && (vertical_end>=12'd354) && (vertical_end<=12'd373)//S
		 ||(horizontal_end>=12'd234) && (horizontal_end<=12'd253) && (vertical_end>=12'd194) && (vertical_end<=12'd264)//S
		 ||(horizontal_end>=12'd315) && (horizontal_end<=12'd334) && (vertical_end>=12'd285) && (vertical_end<=12'd353)//S
		 ||(horizontal_end>=12'd354) && (horizontal_end<=12'd403) && (vertical_end>=12'd174) && (vertical_end<=12'd194)//I
		 ||(horizontal_end>=12'd354) && (horizontal_end<=12'd403) && (vertical_end>=12'd353) && (vertical_end<=12'd373)//I
		 ||(horizontal_end>=12'd369) && (horizontal_end<=12'd389) && (vertical_end>=12'd195) && (vertical_end<=12'd352)//I
		 ||(horizontal_end>=12'd423) && (horizontal_end<=12'd522) && (vertical_end>=12'd174) && (vertical_end<=12'd194)//G
		 ||(horizontal_end>=12'd423) && (horizontal_end<=12'd522) && (vertical_end>=12'd354) && (vertical_end<=12'd373)//G
		 ||(horizontal_end>=12'd423) && (horizontal_end<=12'd442) && (vertical_end>=12'd195) && (vertical_end<=12'd353)//G
		 ||(horizontal_end>=12'd503) && (horizontal_end<=12'd522) && (vertical_end>=12'd303) && (vertical_end<=12'd353)//G
		 ||(horizontal_end>=12'd542) && (horizontal_end<=12'd561) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//N
		 ||(horizontal_end>=12'd624) && (horizontal_end<=12'd643) && (vertical_end>=12'd174) && (vertical_end<=12'd373)//N
		 ||(horizontal_end>=12'd561) && (horizontal_end<=12'd566) && (vertical_end>=12'd174) && (vertical_end<=12'd193)
		 ||(horizontal_end>=12'd567) && (horizontal_end<=12'd572) && (vertical_end>=12'd194) && (vertical_end<=12'd213)
		 ||(horizontal_end>=12'd573) && (horizontal_end<=12'd578) && (vertical_end>=12'd214) && (vertical_end<=12'd233)
		 ||(horizontal_end>=12'd579) && (horizontal_end<=12'd584) && (vertical_end>=12'd234) && (vertical_end<=12'd253)
		 ||(horizontal_end>=12'd585) && (horizontal_end<=12'd590) && (vertical_end>=12'd254) && (vertical_end<=12'd273)
		 ||(horizontal_end>=12'd591) && (horizontal_end<=12'd596) && (vertical_end>=12'd274) && (vertical_end<=12'd293)
		 ||(horizontal_end>=12'd597) && (horizontal_end<=12'd602) && (vertical_end>=12'd294) && (vertical_end<=12'd313)
		 ||(horizontal_end>=12'd603) && (horizontal_end<=12'd608) && (vertical_end>=12'd314) && (vertical_end<=12'd333)
		 ||(horizontal_end>=12'd609) && (horizontal_end<=12'd614) && (vertical_end>=12'd334) && (vertical_end<=12'd353)
		 ||(horizontal_end>=12'd605) && (horizontal_end<=12'd624) && (vertical_end>=12'd354) && (vertical_end<=12'd373)
		 )
			vpg_r<=8'd120;
		else
			vpg_r<=8'd255;
		end
	else
		vpg_r<=8'd255;
end
endmodule
