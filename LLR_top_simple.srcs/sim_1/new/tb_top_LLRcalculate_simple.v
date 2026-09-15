`timescale 1ns / 1ps

module tb_top_LLRcalculate_simple();

    // 参数定义
    parameter DATA_WIDTH = 16;
    parameter CLK_PERIOD = 10;
    
    reg clk;
    reg rst_n;
    reg start_llr_cal;
    reg signed [15:0] Lc;
    reg signed [159:0] y_re;
    reg signed [159:0] y_im;
    
    wire signed [DATA_WIDTH-1:0] softOut;
    wire calc_done;
    wire llr_calc_done;
    
    // 时钟
    always #(CLK_PERIOD/2) clk = ~clk;
    
    // 实例化
    top_LLRcalculate #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_STATES(8),
        .tbDepth(2),
        .LOG_MIN(-32768)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_llr_cal(start_llr_cal),
        .Lc(Lc),
        .y_re(y_re),
        .y_im(y_im),
        .softOut(softOut),
        .calc_done(calc_done),
        .llr_calc_done(llr_calc_done)
    );
    
    // 定义40组测试数据
    reg [159:0] y_real_data [1:40];
    reg [159:0] y_imag_data [1:40];
    
    integer i;
    integer test_num = 1;
    
    // 初始化测试数据
    initial begin
        // 实部数据
        y_real_data[1] = 160'h0BEF033C07EA07EFFC341808016F05BCF73C0709;
        y_real_data[2] = 160'h08530308F12BFC4D07D804E807AF0694080107CA;
        y_real_data[3] = 160'hFAC5F7D7FC61F5E6F84C03D6FD4AF9ED0136FF6C;
        y_real_data[4] = 160'hFE68F6C7F9E7FC95F9B3F6C3F40004E6FF2AF5DB;
        y_real_data[5] = 160'h017B035AFFD10753FC5A038D067FFCA701B50803;
        y_real_data[6] = 160'hFF7A094D073509FAF6C30CE906590588048508BE;
        y_real_data[7] = 160'hFE05F4A8FE03F3DAFB2D01A0046BFC2907311069;
        y_real_data[8] = 160'hFE24FAC603F7FD78001BF173F5E5F77EF22BFC21;
        y_real_data[9] = 160'h0145031505CAFB12FB500156FAB00A89FA45FE58;
        y_real_data[10] = 160'hFF6909D0021200A001BA06F9FD4606F0FF2BFC51;
        y_real_data[11] = 160'h083FFE32FB03F9EFFBD2FDF50081000B04F80109;
        y_real_data[12] = 160'h016003E300B7FDE6050A00DC00E7F8B2078FF9FF;
        y_real_data[13] = 160'h0D2D0C9DFFAE03A5FEAF03CE031B04D905EFFDFB;
        y_real_data[14] = 160'hFC0BF4B9FDDF026EFF04FE0A00E10131FC1405A5;
        y_real_data[15] = 160'hF309F0C6FE39036DFD09037BF886016EFE050124;
        y_real_data[16] = 160'h079EFCA6F799026B07E506FF0451060902EA0073;
        y_real_data[17] = 160'hF2800D7C01AA00E7FF47F737FE55058504BBFE46;
        y_real_data[18] = 160'hFCAFFCC406E8F8530225016BFB81FD440056F81C;
        y_real_data[19] = 160'hF50CFD2E001DF907F4E1FB26FB19009C0464F95C;
        y_real_data[20] = 160'h034BFA3BFE740008FFADFD640717FB59FECF0DAF;
        y_real_data[21] = 160'h023D024904C200220A730AF50A40016AFB9C0586;
        y_real_data[22] = 160'h08E4F910F57205B905CD0D6F0DD1074504370138;
        y_real_data[23] = 160'hF671F8A6FC1CF735FCD1FB44FE09FA90F9790496;
        y_real_data[24] = 160'hFBB3F93C0171022DFB110211F912F399F5F3F862;
        y_real_data[25] = 160'h0918FFA80D5806A4FF5903A103A2071AFFD90100;
        y_real_data[26] = 160'h0AA10364008DFFE3FC64FCAA0428047404FE038D;
        y_real_data[27] = 160'hF9AEF65BFE35F951FE8FFACE0AC9FF2F047FF8C2;
        y_real_data[28] = 160'h0067044B04AC0337FAB3F6DDFB3801E601DA0114;
        y_real_data[29] = 160'h07FCF7700475038408A20A53FFC0FEC20BE6FDAA;
        y_real_data[30] = 160'h0472023604080736FEEFFCBA0684FF8704C50656;
        y_real_data[31] = 160'h049303D8F73AFA7C04A8FFB8FF0408E2FFBD02AF;
        y_real_data[32] = 160'hF7F2039B028EFB910331059F08B2F9C604370537;
        y_real_data[33] = 160'hFF500222FF5B07C2FA7603C60806FAD2FA38FE69;
        y_real_data[34] = 160'hF4C602B60A9402AB00D3020DFEFFFB37FC880B6D;
        y_real_data[35] = 160'h0240008FF79BFC77FD9DF760FB83F722FF2DF7B9;
        y_real_data[36] = 160'h09B8064CFBE700EDFAD7F9AF04EB004706800AC5;
        y_real_data[37] = 160'hFEC2FB78FBA600A801DA091BFE8605A905ED0657;
        y_real_data[38] = 160'hF43AF988032EFD6E0569F9B60308F741F68DFCC6;
        y_real_data[39] = 160'h062DFFC6F9BEFBACF670FDBBF936024AFC95FE60;
        
        // 虚部数据
        y_imag_data[1] = 160'h08630920FFD000C5124E10C102E7F95705410A59;
        y_imag_data[2] = 160'hF263F7EC0489F82FF6B3F939FC8104A5089CF930;
        y_imag_data[3] = 160'h05B700E706DEF762FD9C0303FFF6FC03FDCFFAA3;
        y_imag_data[4] = 160'h02D90693FBAB0843070D0F99FD9801AE06CE002F;
        y_imag_data[5] = 160'hF677F64902D710ED036CFCAB023507C00CEA05A5;
        y_imag_data[6] = 160'hF53AF11EFD1EF6B3F86FFC920264FB6BFC56FAFD;
        y_imag_data[7] = 160'hFDB8052BFE680088F886F12CFADAFAA5F61300A8;
        y_imag_data[8] = 160'h00A20B7202D4FEBF02B707C7FEC5FBABFEFBFE85;
        y_imag_data[9] = 160'h0575023B04550437F5AE07B7FEB2058E1236FF37;
        y_imag_data[10] = 160'hFF93FED10115FCE2FBF2FD48055504ACFD850291;
        y_imag_data[11] = 160'hFA9DFA85F57EF96E05ACFB56F6CEFEF9FDC0F630;
        y_imag_data[12] = 160'h066BEDB6FC69F97CF61DFF41FDFAF9ACFAC0050D;
        y_imag_data[13] = 160'h05DCF713023F05A802A802910AD6F85D006E0545;
        y_imag_data[14] = 160'h0048066AFC74FEA908F006EEFCBDFA640263FA9C;
        y_imag_data[15] = 160'hEEF5FF76FC05019DF22CF492FA8A00290677035B;
        y_imag_data[16] = 160'h0411FCA6FB5F035AFC6DFFC7FCFDF848FFDDF6A6;
        y_imag_data[17] = 160'h06720A3E006BFB30FC0908CC00C90373FEF2FD57;
        y_imag_data[18] = 160'hFB7D045FFE5FF82504A703BB056E0CB7082D0290;
        y_imag_data[19] = 160'h01E4FE28F750FC38FE42FD2DF841008CFA8DFF4C;
        y_imag_data[20] = 160'h035A023CFD09F7E1FB6AFE8F00DD06C8FE77016A;
        y_imag_data[21] = 160'hFA33FDAB0597F8C401E503CFFF550157FAA102CA;
        y_imag_data[22] = 160'hFA33FE73F4EE001AFBB4F996FFFBFF6CFF0CFEFB;
        y_imag_data[23] = 160'h04E90037F7E7011FF1C3001405A704BDFE4AFF14;
        y_imag_data[24] = 160'h008C081B05E903ED076E0408040CFD1C01B70A35;
        y_imag_data[25] = 160'h057CF752FE5902DB046105BB023C02B307510244;
        y_imag_data[26] = 160'h02F2006CFF79FBCDF700F3340DF3014A010C0512;
        y_imag_data[27] = 160'hFE9E0652F6A4F6C4FD91FE15FC07FC62F1AFEEDB;
        y_imag_data[28] = 160'h096F00DF00950192008600CFFCE604BFFEA5FE4E;
        y_imag_data[29] = 160'h0262FF50FACD0C300B0EFA320791077B09530187;
        y_imag_data[30] = 160'h02A6FF4B0168FD64F969FD9DFE23FA2FF629FCBE;
        y_imag_data[31] = 160'h0786FD44FD80FF5CFDD304170150F930FBC003F8;
        y_imag_data[32] = 160'hF8C4F41BF8EAFFA1008FF712FC2CF9D5FE72FD82;
        y_imag_data[33] = 160'hFD7905F1FA660D0F0295003301C501D10238F961;
        y_imag_data[34] = 160'hFE7F017E07C90610006D06C3FF92059DFC7FF6AF;
        y_imag_data[35] = 160'hF702FAC6F49AFBFE04A5FF750087FC7FFC44FCD1;
        y_imag_data[36] = 160'hFA7AFE4D029EFB97FD82F68EF6190014FAC3FCB1;
        y_imag_data[37] = 160'h0EEE029DFB88F102FC02FD8FFAFEFE4AFC7A01F7;
        y_imag_data[38] = 160'hF58D0632FE70FCBF0E66FA0C05DD03FD01430297;
        y_imag_data[39] = 160'h0092FBD5F3ABFD0300D3FAD002CA044802360243;
    end
    
    // 测试主程序
    initial begin
        // 初始化
        clk = 0;
        rst_n = 0;
        start_llr_cal = 0;
        Lc = 16'd2;
        
        // 复位
        #20;
        rst_n = 1;
        #20;
        
        $display("=== 40组数据测试 ===");
        $display("开始时间: %t", $time);
        
        // 对每组数据重复测试3次
        for (i = 1; i <= 40; i = i + 1) begin
            $display("\n测试第 %0d 组数据:", i);
            
            // 第一次输入
            $display("  第%0d 次输入:" ,i);
            y_re = y_real_data[i];
            y_im = y_imag_data[i];
            
            start_llr_cal = 1;
            #(CLK_PERIOD);
            start_llr_cal = 0;
            
            // 等待calc_done信号
            @(posedge calc_done);
            $display("  第1次结果: softOut = %d", softOut);
            #10;
        end
        
        #100;
        $display("\n=== 所有测试完成 ===");
        $finish;
    end
    
    // 监控信号
    initial begin
        $monitor("[%0t] start=%b, calc_done=%b, llr_calc_done=%b, softOut=%d", 
                $time, start_llr_cal, calc_done, llr_calc_done, softOut);
    end
    
    // 生成VCD
    initial begin
        $dumpfile("data_test.vcd");
        $dumpvars(0, tb_top_LLRcalculate_simple);
    end

endmodule