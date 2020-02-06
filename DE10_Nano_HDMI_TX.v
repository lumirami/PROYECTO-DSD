
//`define ENABLE_HPS

module DE10_Nano_HDMI_TX(


      ///////// FPGA /////////
      input              FPGA_CLK1_50,
      ///////// HDMI /////////
      inout              HDMI_I2C_SCL,
      inout              HDMI_I2C_SDA,
      inout              HDMI_I2S,
      inout              HDMI_LRCLK,
      inout              HDMI_MCLK,
      inout              HDMI_SCLK,
      output             HDMI_TX_CLK,
      output      [23:0] HDMI_TX_D,
      output             HDMI_TX_DE,
      output             HDMI_TX_HS,
      input              HDMI_TX_INT,
      output             HDMI_TX_VS,

      ///////// KEY /////////
      input       [1:0]  KEY,

      ///////// LED /////////
      output      [7:0]  LED,

      ///////// SW /////////
      input       [2:0]  SW
);



//=======================================================
//  REG/WIRE declarations
//=======================================================
wire				reset_n;
wire				pll_1200k;
reg	[12:0]	counter_1200k;
reg				en_150;
wire				vpg_mode_change;
wire	[3:0]		vpg_mode;
wire 			   AUD_CTRL_CLK;
//Video Pattern Generator
wire	[3:0]		vpg_disp_mode;
wire				vpg_pclk;
wire				vpg_de, vpg_hs, vpg_vs;
wire	[23:0]	vpg_data;
assign HDMI_MCLK  = 1'b z;

//=======================================================
//  Structural coding
//=======================================================
assign LED[3:0] = vpg_mode;
//assign reset_n = 1'b1;
assign LED[7] = counter_1200k[12];
//system clock
sys_pll u_sys_pll (
	.refclk(FPGA_CLK1_50),
	.rst(!KEY[0]),
	.outclk_0(pll_1200k),		// 1.2M Hz
	.outclk_1(AUD_CTRL_CLK),	// 1.536M Hz
	.locked(reset_n) );

//video pattern resolution select
vpg_mode u_vpg_mode (
	.reset_n(reset_n),
	.clk(pll_1200k),
	.clk_en(en_150),
	.mode_button(KEY[1]),
	.vpg_mode_change(vpg_mode_change),
	.vpg_mode(vpg_mode) );

//pattern generator
vpg u_vpg (
	.clk_50(FPGA_CLK1_50),
	.reset_n(reset_n),
	.mode(vpg_mode),
	.mode_change(vpg_mode_change),
	.vpg_pclk(HDMI_TX_CLK),
	.vpg_de(HDMI_TX_DE),
	.vpg_hs(HDMI_TX_HS),
	.vpg_vs(HDMI_TX_VS),
	.vpg_r(HDMI_TX_D[23:16]),
	.vpg_g(HDMI_TX_D[15:8]),
	.vpg_b(HDMI_TX_D[7:0]),
	.SW(SW[2:0])
);
//HDMI I2C
I2C_HDMI_Config u_I2C_HDMI_Config (
	.iCLK(FPGA_CLK1_50),
	.iRST_N(reset_n),
	.I2C_SCLK(HDMI_I2C_SCL),
	.I2C_SDAT(HDMI_I2C_SDA),
	.HDMI_TX_INT(HDMI_TX_INT)
	 );

	//Audio
AUDIO_IF u_AVG(
	.clk(AUD_CTRL_CLK),
	.reset_n(KEY[0]),
	.sclk(HDMI_SCLK),
	.lrclk(HDMI_LRCLK),
	.i2s(HDMI_I2S)
);

always@(posedge pll_1200k or negedge reset_n)
begin
	if (!reset_n)
	begin
		counter_1200k <= 13'b0;
		en_150 <= 1'b0;				//frequency divider
	end
	else
	begin
		counter_1200k <= counter_1200k + 13'b1;
		en_150 <= &counter_1200k;
	end
end


endmodule
