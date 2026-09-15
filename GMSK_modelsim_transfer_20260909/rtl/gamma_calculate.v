`timescale 1ns / 1ps
module gamma_calculate #(
    parameter DATA_WIDTH     = 16,
    parameter M              = 2,
    parameter NUM_STATES     = 8,
    parameter SPS            = 10,
    parameter NUM_SAMPLES    = 160
)(
    input wire clk,
    input wire rst_n,
    (* KEEP = "{TRUE|FALSE |SOFT}"*) input wire start_calc,
    
    (* KEEP = "{TRUE|FALSE |SOFT}"*) input wire signed [159:0] y_re,
    (* KEEP = "{TRUE|FALSE |SOFT}"*) input wire signed [159:0] y_im,
    input wire signed [15:0] Lc,
    input wire signed [127:0] alpha_2,
    
    (* KEEP = "{TRUE|FALSE |SOFT}"*) output reg signed [127:0] gamma_input_0,
    (* KEEP = "{TRUE|FALSE |SOFT}"*) output reg signed [127:0] gamma_input_1,
    (* KEEP = "{TRUE|FALSE |SOFT}"*) output reg signed [255:0] gamma,
    (* KEEP = "{TRUE|FALSE |SOFT}"*) output reg calc_done
);
    
    localparam [2:0] IDLE              = 3'b000;
    localparam [2:0] INIT              = 3'b001;
    localparam [2:0] CALC_CORRELATION  = 3'b010;
    localparam [2:0] ACCUMULATE        = 3'b011;
    localparam [2:0] UPDATE_tempSum    = 3'b100;
    localparam [2:0] UPDATE_GAMMA      = 3'b101;
    localparam [2:0] DONE              = 3'b110;

    function automatic signed [15:0] sat_add16;
        input signed [15:0] a;
        input signed [15:0] b;
        reg signed [16:0] sum;
        begin
            sum = a + b;
            if (sum > 17'sd32767)
                sat_add16 = 16'sh7FFF;
            else if (sum < -17'sd32768)
                sat_add16 = -16'sd32768;
            else
                sat_add16 = sum[15:0];
        end
    endfunction
    
    reg signed [2559:0] outReVal = 'h03EF03C9038C033A02D4025D01D9014C00BC002E0030008100BE00E400F100E400BE00810030FFD2FC01FC08FC12FC1AFC1DFC1AFC12FC08FC01FC01FF44FEB4FE27FDA3FD2CFCC6FC74FC37FC11FC01FF44FEB4FE27FDA3FD2CFCC6FC74FC37FC11FC01FC01FC08FC12FC1AFC1DFC1AFC12FC08FC01FC010030008100BE00E400F100E400BE00810030FFD203EF03C9038C033A02D4025D01D9014C00BC002EFC11FC37FC74FCC6FD2CFDA3FE27FEB4FF44FFD2FFD0FF7FFF42FF1CFF0FFF1CFF42FF7FFFD0002E03FF03F803EE03E603E303E603EE03F803FF03FF00BC014C01D9025D02D4033A038C03C903EF03FF00BC014C01D9025D02D4033A038C03C903EF03FF03FF03F803EE03E603E303E603EE03F803FF03FFFFD0FF7FFF42FF1CFF0FFF1CFF42FF7FFFD0002EFC11FC37FC74FCC6FD2CFDA3FE27FEB4FF44FFD2;
    reg signed [2559:0] outImVal = 'hFF44FEB4FE27FDA3FD2CFCC6FC74FC37FC11FC01FC01FC08FC12FC1AFC1DFC1AFC12FC08FC01FC010030008100BE00E400F100E400BE00810030FFD203EF03C9038C033A02D4025D01D9014C00BC002EFC11FC37FC74FCC6FD2CFDA3FE27FEB4FF44FFD2FFD0FF7FFF42FF1CFF0FFF1CFF42FF7FFFD0002E03FF03F803EE03E603E303E603EE03F803FF03FF00BC014C01D9025D02D4033A038C03C903EF03FF00BC014C01D9025D02D4033A038C03C903EF03FF03FF03F803EE03E603E303E603EE03F803FF03FFFFD0FF7FFF42FF1CFF0FFF1CFF42FF7FFFD0002EFC11FC37FC74FCC6FD2CFDA3FE27FEB4FF44FFD203EF03C9038C033A02D4025D01D9014C00BC002E0030008100BE00E400F100E400BE00810030FFD2FC01FC08FC12FC1AFC1DFC1AFC12FC08FC01FC01FF44FEB4FE27FDA3FD2CFCC6FC74FC37FC11FC01;
    reg signed [47:0] nextStateInd = 'b001000101100111110011010101100001000011010111110;
    
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed [2*DATA_WIDTH:0] tempSum [0:NUM_STATES-1][0:M-1];
    reg signed [2*DATA_WIDTH:0] corr_re_im [0:NUM_STATES-1][0:M-1][0:SPS-1];
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg [2:0] current_state, next_state;
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed [159:0] middle_re, middle_im;
    reg signed [2*DATA_WIDTH:0] tempSum_comb [0:NUM_STATES-1][0:M-1];
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed [127:0] middle_gamma_input_0, middle_gamma_input_1;
    (* KEEP = "{TRUE|FALSE |SOFT}"*) reg signed [255:0] middle_gamma;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    always @(*) begin
        case (current_state)
            IDLE:               next_state = start_calc ? INIT : IDLE;
            INIT:               next_state = CALC_CORRELATION;
            CALC_CORRELATION:   next_state = ACCUMULATE;
            ACCUMULATE :        next_state = UPDATE_tempSum;
            UPDATE_tempSum:     next_state = UPDATE_GAMMA;
            UPDATE_GAMMA:       next_state = DONE;
            DONE:               next_state = IDLE;
            default:            next_state = IDLE;
        endcase
    end
    
    always @(posedge clk) begin
        if (current_state == CALC_CORRELATION) begin
            middle_re <= y_re;
            middle_im <= y_im;
            // ========== 状态 0, 输入 0, 10个采样点 ==========
            corr_re_im[0][0][0] <= $signed(y_re[15:0])   * $signed(outReVal[15:0])      + $signed(y_im[15:0])   * $signed(outImVal[15:0]);
            corr_re_im[0][0][1] <= $signed(y_re[31:16])  * $signed(outReVal[31:16])     + $signed(y_im[31:16])  * $signed(outImVal[31:16]);
            corr_re_im[0][0][2] <= $signed(y_re[47:32])  * $signed(outReVal[47:32])     + $signed(y_im[47:32])  * $signed(outImVal[47:32]); 
            corr_re_im[0][0][3] <= $signed(y_re[63:48])  * $signed(outReVal[63:48])     + $signed(y_im[63:48])  * $signed(outImVal[63:48]);
            corr_re_im[0][0][4] <= $signed(y_re[79:64])  * $signed(outReVal[79:64])     + $signed(y_im[79:64])  * $signed(outImVal[79:64]); 
            corr_re_im[0][0][5] <= $signed(y_re[95:80])  * $signed(outReVal[95:80])     + $signed(y_im[95:80])  * $signed(outImVal[95:80]);  
            corr_re_im[0][0][6] <= $signed(y_re[111:96]) * $signed(outReVal[111:96])    + $signed(y_im[111:96]) * $signed(outImVal[111:96]);   
            corr_re_im[0][0][7] <= $signed(y_re[127:112])* $signed(outReVal[127:112])   + $signed(y_im[127:112])* $signed(outImVal[127:112]);   
            corr_re_im[0][0][8] <= $signed(y_re[143:128])* $signed(outReVal[143:128])   + $signed(y_im[143:128])* $signed(outImVal[143:128]);   
            corr_re_im[0][0][9] <= $signed(y_re[159:144])* $signed(outReVal[159:144])   + $signed(y_im[159:144])* $signed(outImVal[159:144]);   
    
            // ========== 状态 0, 输入 1, 10个采样点 ==========
            corr_re_im[0][1][0] <= $signed(y_re[15:0])   * $signed(outReVal[175:160])   + $signed(y_im[15:0])   * $signed(outImVal[175:160]);
            corr_re_im[0][1][1] <= $signed(y_re[31:16])  * $signed(outReVal[191:176])   + $signed(y_im[31:16])  * $signed(outImVal[191:176]);
            corr_re_im[0][1][2] <= $signed(y_re[47:32])  * $signed(outReVal[207:192])   + $signed(y_im[47:32])  * $signed(outImVal[207:192]);
            corr_re_im[0][1][3] <= $signed(y_re[63:48])  * $signed(outReVal[223:208])   + $signed(y_im[63:48])  * $signed(outImVal[223:208]);
            corr_re_im[0][1][4] <= $signed(y_re[79:64])  * $signed(outReVal[239:224])   + $signed(y_im[79:64])  * $signed(outImVal[239:224]);
            corr_re_im[0][1][5] <= $signed(y_re[95:80])  * $signed(outReVal[255:240])   + $signed(y_im[95:80])  * $signed(outImVal[255:240]);
            corr_re_im[0][1][6] <= $signed(y_re[111:96]) * $signed(outReVal[271:256])   + $signed(y_im[111:96]) * $signed(outImVal[271:256]);
            corr_re_im[0][1][7] <= $signed(y_re[127:112])* $signed(outReVal[287:272])   + $signed(y_im[127:112])* $signed(outImVal[287:272]);
            corr_re_im[0][1][8] <= $signed(y_re[143:128])* $signed(outReVal[303:288])   + $signed(y_im[143:128])* $signed(outImVal[303:288]);
            corr_re_im[0][1][9] <= $signed(y_re[159:144])* $signed(outReVal[319:304])   + $signed(y_im[159:144])* $signed(outImVal[319:304]);
    
            // ========== 状态 1, 输入 0, 10个采样点 ==========
            corr_re_im[1][0][0] <= $signed(y_re[15:0])   * $signed(outReVal[335:320])   + $signed(y_im[15:0])   * $signed(outImVal[335:320]);
            corr_re_im[1][0][1] <= $signed(y_re[31:16])  * $signed(outReVal[351:336])   + $signed(y_im[31:16])  * $signed(outImVal[351:336]);
            corr_re_im[1][0][2] <= $signed(y_re[47:32])  * $signed(outReVal[367:352])   + $signed(y_im[47:32])  * $signed(outImVal[367:352]);
            corr_re_im[1][0][3] <= $signed(y_re[63:48])  * $signed(outReVal[383:368])   + $signed(y_im[63:48])  * $signed(outImVal[383:368]);
            corr_re_im[1][0][4] <= $signed(y_re[79:64])  * $signed(outReVal[399:384])   + $signed(y_im[79:64])  * $signed(outImVal[399:384]);
            corr_re_im[1][0][5] <= $signed(y_re[95:80])  * $signed(outReVal[415:400])   + $signed(y_im[95:80])  * $signed(outImVal[415:400]);
            corr_re_im[1][0][6] <= $signed(y_re[111:96]) * $signed(outReVal[431:416])   + $signed(y_im[111:96]) * $signed(outImVal[431:416]);
            corr_re_im[1][0][7] <= $signed(y_re[127:112])* $signed(outReVal[447:432])   + $signed(y_im[127:112])* $signed(outImVal[447:432]);
            corr_re_im[1][0][8] <= $signed(y_re[143:128])* $signed(outReVal[463:448])   + $signed(y_im[143:128])* $signed(outImVal[463:448]);
            corr_re_im[1][0][9] <= $signed(y_re[159:144])* $signed(outReVal[479:464])   + $signed(y_im[159:144])* $signed(outImVal[479:464]);
    
            // ========== 状态 1, 输入 1, 10个采样点 ==========
            corr_re_im[1][1][0] <= $signed(y_re[15:0])   * $signed(outReVal[495:480])   + $signed(y_im[15:0])   * $signed(outImVal[495:480]);
            corr_re_im[1][1][1] <= $signed(y_re[31:16])  * $signed(outReVal[511:496])   + $signed(y_im[31:16])  * $signed(outImVal[511:496]);
            corr_re_im[1][1][2] <= $signed(y_re[47:32])  * $signed(outReVal[527:512])   + $signed(y_im[47:32])  * $signed(outImVal[527:512]);
            corr_re_im[1][1][3] <= $signed(y_re[63:48])  * $signed(outReVal[543:528])   + $signed(y_im[63:48])  * $signed(outImVal[543:528]);
            corr_re_im[1][1][4] <= $signed(y_re[79:64])  * $signed(outReVal[559:544])   + $signed(y_im[79:64])  * $signed(outImVal[559:544]);
            corr_re_im[1][1][5] <= $signed(y_re[95:80])  * $signed(outReVal[575:560])   + $signed(y_im[95:80])  * $signed(outImVal[575:560]);
            corr_re_im[1][1][6] <= $signed(y_re[111:96]) * $signed(outReVal[591:576])   + $signed(y_im[111:96]) * $signed(outImVal[591:576]);
            corr_re_im[1][1][7] <= $signed(y_re[127:112])* $signed(outReVal[607:592])   + $signed(y_im[127:112])* $signed(outImVal[607:592]);
            corr_re_im[1][1][8] <= $signed(y_re[143:128])* $signed(outReVal[623:608])   + $signed(y_im[143:128])* $signed(outImVal[623:608]);
            corr_re_im[1][1][9] <= $signed(y_re[159:144])* $signed(outReVal[639:624])   + $signed(y_im[159:144])* $signed(outImVal[639:624]);
    
            // ========== 状态 2, 输入 0, 10个采样点 ==========
            corr_re_im[2][0][0] <= $signed(y_re[15:0])   * $signed(outReVal[655:640])   + $signed(y_im[15:0])   * $signed(outImVal[655:640]);
            corr_re_im[2][0][1] <= $signed(y_re[31:16])  * $signed(outReVal[671:656])   + $signed(y_im[31:16])  * $signed(outImVal[671:656]);
            corr_re_im[2][0][2] <= $signed(y_re[47:32])  * $signed(outReVal[687:672])   + $signed(y_im[47:32])  * $signed(outImVal[687:672]);
            corr_re_im[2][0][3] <= $signed(y_re[63:48])  * $signed(outReVal[703:688])   + $signed(y_im[63:48])  * $signed(outImVal[703:688]);
            corr_re_im[2][0][4] <= $signed(y_re[79:64])  * $signed(outReVal[719:704])   + $signed(y_im[79:64])  * $signed(outImVal[719:704]);
            corr_re_im[2][0][5] <= $signed(y_re[95:80])  * $signed(outReVal[735:720])   + $signed(y_im[95:80])  * $signed(outImVal[735:720]);
            corr_re_im[2][0][6] <= $signed(y_re[111:96]) * $signed(outReVal[751:736])   + $signed(y_im[111:96]) * $signed(outImVal[751:736]);
            corr_re_im[2][0][7] <= $signed(y_re[127:112])* $signed(outReVal[767:752])   + $signed(y_im[127:112])* $signed(outImVal[767:752]);
            corr_re_im[2][0][8] <= $signed(y_re[143:128])* $signed(outReVal[783:768])   + $signed(y_im[143:128])* $signed(outImVal[783:768]);
            corr_re_im[2][0][9] <= $signed(y_re[159:144])* $signed(outReVal[799:784])   + $signed(y_im[159:144])* $signed(outImVal[799:784]);
    
            // ========== 状态 2, 输入 1, 10个采样点 ==========
            corr_re_im[2][1][0] <= $signed(y_re[15:0])   * $signed(outReVal[815:800])   + $signed(y_im[15:0])   * $signed(outImVal[815:800]);
            corr_re_im[2][1][1] <= $signed(y_re[31:16])  * $signed(outReVal[831:816])   + $signed(y_im[31:16])  * $signed(outImVal[831:816]);
            corr_re_im[2][1][2] <= $signed(y_re[47:32])  * $signed(outReVal[847:832])   + $signed(y_im[47:32])  * $signed(outImVal[847:832]);
            corr_re_im[2][1][3] <= $signed(y_re[63:48])  * $signed(outReVal[863:848])   + $signed(y_im[63:48])  * $signed(outImVal[863:848]);
            corr_re_im[2][1][4] <= $signed(y_re[79:64])  * $signed(outReVal[879:864])   + $signed(y_im[79:64])  * $signed(outImVal[879:864]);
            corr_re_im[2][1][5] <= $signed(y_re[95:80])  * $signed(outReVal[895:880])   + $signed(y_im[95:80])  * $signed(outImVal[895:880]);
            corr_re_im[2][1][6] <= $signed(y_re[111:96]) * $signed(outReVal[911:896])   + $signed(y_im[111:96]) * $signed(outImVal[911:896]);
            corr_re_im[2][1][7] <= $signed(y_re[127:112])* $signed(outReVal[927:912])   + $signed(y_im[127:112])* $signed(outImVal[927:912]);
            corr_re_im[2][1][8] <= $signed(y_re[143:128])* $signed(outReVal[943:928])   + $signed(y_im[143:128])* $signed(outImVal[943:928]);
            corr_re_im[2][1][9] <= $signed(y_re[159:144])* $signed(outReVal[959:944])   + $signed(y_im[159:144])* $signed(outImVal[959:944]);
    
            // ========== 状态 3, 输入 0, 10个采样点 ==========
            corr_re_im[3][0][0] <= $signed(y_re[15:0])   * $signed(outReVal[975:960])   + $signed(y_im[15:0])   * $signed(outImVal[975:960]);
            corr_re_im[3][0][1] <= $signed(y_re[31:16])  * $signed(outReVal[991:976])   + $signed(y_im[31:16])  * $signed(outImVal[991:976]);
            corr_re_im[3][0][2] <= $signed(y_re[47:32])  * $signed(outReVal[1007:992])  + $signed(y_im[47:32])  * $signed(outImVal[1007:992]);
            corr_re_im[3][0][3] <= $signed(y_re[63:48])  * $signed(outReVal[1023:1008]) + $signed(y_im[63:48])  * $signed(outImVal[1023:1008]);
            corr_re_im[3][0][4] <= $signed(y_re[79:64])  * $signed(outReVal[1039:1024]) + $signed(y_im[79:64])  * $signed(outImVal[1039:1024]);
            corr_re_im[3][0][5] <= $signed(y_re[95:80])  * $signed(outReVal[1055:1040]) + $signed(y_im[95:80])  * $signed(outImVal[1055:1040]);
            corr_re_im[3][0][6] <= $signed(y_re[111:96]) * $signed(outReVal[1071:1056]) + $signed(y_im[111:96]) * $signed(outImVal[1071:1056]);
            corr_re_im[3][0][7] <= $signed(y_re[127:112])* $signed(outReVal[1087:1072]) + $signed(y_im[127:112])* $signed(outImVal[1087:1072]);
            corr_re_im[3][0][8] <= $signed(y_re[143:128])* $signed(outReVal[1103:1088]) + $signed(y_im[143:128])* $signed(outImVal[1103:1088]);
            corr_re_im[3][0][9] <= $signed(y_re[159:144])* $signed(outReVal[1119:1104]) + $signed(y_im[159:144])* $signed(outImVal[1119:1104]);
    
            // ========== 状态 3, 输入 1, 10个采样点 ==========
            corr_re_im[3][1][0] <= $signed(y_re[15:0])   * $signed(outReVal[1135:1120]) + $signed(y_im[15:0])   * $signed(outImVal[1135:1120]);
            corr_re_im[3][1][1] <= $signed(y_re[31:16])  * $signed(outReVal[1151:1136]) + $signed(y_im[31:16])  * $signed(outImVal[1151:1136]);
            corr_re_im[3][1][2] <= $signed(y_re[47:32])  * $signed(outReVal[1167:1152]) + $signed(y_im[47:32])  * $signed(outImVal[1167:1152]);
            corr_re_im[3][1][3] <= $signed(y_re[63:48])  * $signed(outReVal[1183:1168]) + $signed(y_im[63:48])  * $signed(outImVal[1183:1168]);
            corr_re_im[3][1][4] <= $signed(y_re[79:64])  * $signed(outReVal[1199:1184]) + $signed(y_im[79:64])  * $signed(outImVal[1199:1184]);
            corr_re_im[3][1][5] <= $signed(y_re[95:80])  * $signed(outReVal[1215:1200]) + $signed(y_im[95:80])  * $signed(outImVal[1215:1200]);
            corr_re_im[3][1][6] <= $signed(y_re[111:96]) * $signed(outReVal[1231:1216]) + $signed(y_im[111:96]) * $signed(outImVal[1231:1216]);
            corr_re_im[3][1][7] <= $signed(y_re[127:112])* $signed(outReVal[1247:1232]) + $signed(y_im[127:112])* $signed(outImVal[1247:1232]);
            corr_re_im[3][1][8] <= $signed(y_re[143:128])* $signed(outReVal[1263:1248]) + $signed(y_im[143:128])* $signed(outImVal[1263:1248]);
            corr_re_im[3][1][9] <= $signed(y_re[159:144])* $signed(outReVal[1279:1264]) + $signed(y_im[159:144])* $signed(outImVal[1279:1264]);
    
            // ========== 状态 4, 输入 0, 10个采样点 ==========
            corr_re_im[4][0][0] <= $signed(y_re[15:0])   * $signed(outReVal[1295:1280]) + $signed(y_im[15:0])   * $signed(outImVal[1295:1280]);
            corr_re_im[4][0][1] <= $signed(y_re[31:16])  * $signed(outReVal[1311:1296]) + $signed(y_im[31:16])  * $signed(outImVal[1311:1296]);
            corr_re_im[4][0][2] <= $signed(y_re[47:32])  * $signed(outReVal[1327:1312]) + $signed(y_im[47:32])  * $signed(outImVal[1327:1312]);
            corr_re_im[4][0][3] <= $signed(y_re[63:48])  * $signed(outReVal[1343:1328]) + $signed(y_im[63:48])  * $signed(outImVal[1343:1328]);
            corr_re_im[4][0][4] <= $signed(y_re[79:64])  * $signed(outReVal[1359:1344]) + $signed(y_im[79:64])  * $signed(outImVal[1359:1344]);
            corr_re_im[4][0][5] <= $signed(y_re[95:80])  * $signed(outReVal[1375:1360]) + $signed(y_im[95:80])  * $signed(outImVal[1375:1360]);
            corr_re_im[4][0][6] <= $signed(y_re[111:96]) * $signed(outReVal[1391:1376]) + $signed(y_im[111:96]) * $signed(outImVal[1391:1376]);
            corr_re_im[4][0][7] <= $signed(y_re[127:112])* $signed(outReVal[1407:1392]) + $signed(y_im[127:112])* $signed(outImVal[1407:1392]);
            corr_re_im[4][0][8] <= $signed(y_re[143:128])* $signed(outReVal[1423:1408]) + $signed(y_im[143:128])* $signed(outImVal[1423:1408]);
            corr_re_im[4][0][9] <= $signed(y_re[159:144])* $signed(outReVal[1439:1424]) + $signed(y_im[159:144])* $signed(outImVal[1439:1424]);
    
            // ========== 状态 4, 输入 1, 10个采样点 ==========
            corr_re_im[4][1][0] <= $signed(y_re[15:0])   * $signed(outReVal[1455:1440]) + $signed(y_im[15:0])   * $signed(outImVal[1455:1440]);
            corr_re_im[4][1][1] <= $signed(y_re[31:16])  * $signed(outReVal[1471:1456]) + $signed(y_im[31:16])  * $signed(outImVal[1471:1456]);
            corr_re_im[4][1][2] <= $signed(y_re[47:32])  * $signed(outReVal[1487:1472]) + $signed(y_im[47:32])  * $signed(outImVal[1487:1472]);
            corr_re_im[4][1][3] <= $signed(y_re[63:48])  * $signed(outReVal[1503:1488]) + $signed(y_im[63:48])  * $signed(outImVal[1503:1488]);
            corr_re_im[4][1][4] <= $signed(y_re[79:64])  * $signed(outReVal[1519:1504]) + $signed(y_im[79:64])  * $signed(outImVal[1519:1504]);
            corr_re_im[4][1][5] <= $signed(y_re[95:80])  * $signed(outReVal[1535:1520]) + $signed(y_im[95:80])  * $signed(outImVal[1535:1520]);
            corr_re_im[4][1][6] <= $signed(y_re[111:96]) * $signed(outReVal[1551:1536]) + $signed(y_im[111:96]) * $signed(outImVal[1551:1536]);
            corr_re_im[4][1][7] <= $signed(y_re[127:112])* $signed(outReVal[1567:1552]) + $signed(y_im[127:112])* $signed(outImVal[1567:1552]);
            corr_re_im[4][1][8] <= $signed(y_re[143:128])* $signed(outReVal[1583:1568]) + $signed(y_im[143:128])* $signed(outImVal[1583:1568]);
            corr_re_im[4][1][9] <= $signed(y_re[159:144])* $signed(outReVal[1599:1584]) + $signed(y_im[159:144])* $signed(outImVal[1599:1584]);
    
            // ========== 状态 5, 输入 0, 10个采样点 ==========
            corr_re_im[5][0][0] <= $signed(y_re[15:0])   * $signed(outReVal[1615:1600]) + $signed(y_im[15:0])   * $signed(outImVal[1615:1600]);
            corr_re_im[5][0][1] <= $signed(y_re[31:16])  * $signed(outReVal[1631:1616]) + $signed(y_im[31:16])  * $signed(outImVal[1631:1616]);
            corr_re_im[5][0][2] <= $signed(y_re[47:32])  * $signed(outReVal[1647:1632]) + $signed(y_im[47:32])  * $signed(outImVal[1647:1632]);
            corr_re_im[5][0][3] <= $signed(y_re[63:48])  * $signed(outReVal[1663:1648]) + $signed(y_im[63:48])  * $signed(outImVal[1663:1648]);
            corr_re_im[5][0][4] <= $signed(y_re[79:64])  * $signed(outReVal[1679:1664]) + $signed(y_im[79:64])  * $signed(outImVal[1679:1664]);
            corr_re_im[5][0][5] <= $signed(y_re[95:80])  * $signed(outReVal[1695:1680]) + $signed(y_im[95:80])  * $signed(outImVal[1695:1680]);
            corr_re_im[5][0][6] <= $signed(y_re[111:96]) * $signed(outReVal[1711:1696]) + $signed(y_im[111:96]) * $signed(outImVal[1711:1696]);
            corr_re_im[5][0][7] <= $signed(y_re[127:112])* $signed(outReVal[1727:1712]) + $signed(y_im[127:112])* $signed(outImVal[1727:1712]);
            corr_re_im[5][0][8] <= $signed(y_re[143:128])* $signed(outReVal[1743:1728]) + $signed(y_im[143:128])* $signed(outImVal[1743:1728]);
            corr_re_im[5][0][9] <= $signed(y_re[159:144])* $signed(outReVal[1759:1744]) + $signed(y_im[159:144])* $signed(outImVal[1759:1744]);
    
            // ========== 状态 5, 输入 1, 10个采样点 ==========
            corr_re_im[5][1][0] <= $signed(y_re[15:0])   * $signed(outReVal[1775:1760]) + $signed(y_im[15:0])   * $signed(outImVal[1775:1760]);
            corr_re_im[5][1][1] <= $signed(y_re[31:16])  * $signed(outReVal[1791:1776]) + $signed(y_im[31:16])  * $signed(outImVal[1791:1776]);
            corr_re_im[5][1][2] <= $signed(y_re[47:32])  * $signed(outReVal[1807:1792]) + $signed(y_im[47:32])  * $signed(outImVal[1807:1792]);
            corr_re_im[5][1][3] <= $signed(y_re[63:48])  * $signed(outReVal[1823:1808]) + $signed(y_im[63:48])  * $signed(outImVal[1823:1808]);
            corr_re_im[5][1][4] <= $signed(y_re[79:64])  * $signed(outReVal[1839:1824]) + $signed(y_im[79:64])  * $signed(outImVal[1839:1824]);
            corr_re_im[5][1][5] <= $signed(y_re[95:80])  * $signed(outReVal[1855:1840]) + $signed(y_im[95:80])  * $signed(outImVal[1855:1840]);
            corr_re_im[5][1][6] <= $signed(y_re[111:96]) * $signed(outReVal[1871:1856]) + $signed(y_im[111:96]) * $signed(outImVal[1871:1856]);
            corr_re_im[5][1][7] <= $signed(y_re[127:112])* $signed(outReVal[1887:1872]) + $signed(y_im[127:112])* $signed(outImVal[1887:1872]);
            corr_re_im[5][1][8] <= $signed(y_re[143:128])* $signed(outReVal[1903:1888]) + $signed(y_im[143:128])* $signed(outImVal[1903:1888]);
            corr_re_im[5][1][9] <= $signed(y_re[159:144])* $signed(outReVal[1919:1904]) + $signed(y_im[159:144])* $signed(outImVal[1919:1904]);
    
            // ========== 状态 6, 输入 0, 10个采样点 ==========
            corr_re_im[6][0][0] <= $signed(y_re[15:0])   * $signed(outReVal[1935:1920]) + $signed(y_im[15:0])   * $signed(outImVal[1935:1920]);
            corr_re_im[6][0][1] <= $signed(y_re[31:16])  * $signed(outReVal[1951:1936]) + $signed(y_im[31:16])  * $signed(outImVal[1951:1936]);
            corr_re_im[6][0][2] <= $signed(y_re[47:32])  * $signed(outReVal[1967:1952]) + $signed(y_im[47:32])  * $signed(outImVal[1967:1952]);
            corr_re_im[6][0][3] <= $signed(y_re[63:48])  * $signed(outReVal[1983:1968]) + $signed(y_im[63:48])  * $signed(outImVal[1983:1968]);
            corr_re_im[6][0][4] <= $signed(y_re[79:64])  * $signed(outReVal[1999:1984]) + $signed(y_im[79:64])  * $signed(outImVal[1999:1984]);
            corr_re_im[6][0][5] <= $signed(y_re[95:80])  * $signed(outReVal[2015:2000]) + $signed(y_im[95:80])  * $signed(outImVal[2015:2000]);
            corr_re_im[6][0][6] <= $signed(y_re[111:96]) * $signed(outReVal[2031:2016]) + $signed(y_im[111:96]) * $signed(outImVal[2031:2016]);
            corr_re_im[6][0][7] <= $signed(y_re[127:112])* $signed(outReVal[2047:2032]) + $signed(y_im[127:112])* $signed(outImVal[2047:2032]);
            corr_re_im[6][0][8] <= $signed(y_re[143:128])* $signed(outReVal[2063:2048]) + $signed(y_im[143:128])* $signed(outImVal[2063:2048]);
            corr_re_im[6][0][9] <= $signed(y_re[159:144])* $signed(outReVal[2079:2064]) + $signed(y_im[159:144])* $signed(outImVal[2079:2064]);
    
            // ========== 状态 6, 输入 1, 10个采样点 ==========
            corr_re_im[6][1][0] <= $signed(y_re[15:0])   * $signed(outReVal[2095:2080]) + $signed(y_im[15:0])   * $signed(outImVal[2095:2080]);
            corr_re_im[6][1][1] <= $signed(y_re[31:16])  * $signed(outReVal[2111:2096]) + $signed(y_im[31:16])  * $signed(outImVal[2111:2096]);
            corr_re_im[6][1][2] <= $signed(y_re[47:32])  * $signed(outReVal[2127:2112]) + $signed(y_im[47:32])  * $signed(outImVal[2127:2112]);
            corr_re_im[6][1][3] <= $signed(y_re[63:48])  * $signed(outReVal[2143:2128]) + $signed(y_im[63:48])  * $signed(outImVal[2143:2128]);
            corr_re_im[6][1][4] <= $signed(y_re[79:64])  * $signed(outReVal[2159:2144]) + $signed(y_im[79:64])  * $signed(outImVal[2159:2144]);
            corr_re_im[6][1][5] <= $signed(y_re[95:80])  * $signed(outReVal[2175:2160]) + $signed(y_im[95:80])  * $signed(outImVal[2175:2160]);
            corr_re_im[6][1][6] <= $signed(y_re[111:96]) * $signed(outReVal[2191:2176]) + $signed(y_im[111:96]) * $signed(outImVal[2191:2176]);
            corr_re_im[6][1][7] <= $signed(y_re[127:112])* $signed(outReVal[2207:2192]) + $signed(y_im[127:112])* $signed(outImVal[2207:2192]);
            corr_re_im[6][1][8] <= $signed(y_re[143:128])* $signed(outReVal[2223:2208]) + $signed(y_im[143:128])* $signed(outImVal[2223:2208]);
            corr_re_im[6][1][9] <= $signed(y_re[159:144])* $signed(outReVal[2239:2224]) + $signed(y_im[159:144])* $signed(outImVal[2239:2224]);
    
            // ========== 状态 7, 输入 0, 10个采样点 ==========
            corr_re_im[7][0][0] <= $signed(y_re[15:0])   * $signed(outReVal[2255:2240]) + $signed(y_im[15:0])   * $signed(outImVal[2255:2240]);
            corr_re_im[7][0][1] <= $signed(y_re[31:16])  * $signed(outReVal[2271:2256]) + $signed(y_im[31:16])  * $signed(outImVal[2271:2256]);
            corr_re_im[7][0][2] <= $signed(y_re[47:32])  * $signed(outReVal[2287:2272]) + $signed(y_im[47:32])  * $signed(outImVal[2287:2272]);
            corr_re_im[7][0][3] <= $signed(y_re[63:48])  * $signed(outReVal[2303:2288]) + $signed(y_im[63:48])  * $signed(outImVal[2303:2288]);
            corr_re_im[7][0][4] <= $signed(y_re[79:64])  * $signed(outReVal[2319:2304]) + $signed(y_im[79:64])  * $signed(outImVal[2319:2304]);
            corr_re_im[7][0][5] <= $signed(y_re[95:80])  * $signed(outReVal[2335:2320]) + $signed(y_im[95:80])  * $signed(outImVal[2335:2320]);
            corr_re_im[7][0][6] <= $signed(y_re[111:96]) * $signed(outReVal[2351:2336]) + $signed(y_im[111:96]) * $signed(outImVal[2351:2336]);
            corr_re_im[7][0][7] <= $signed(y_re[127:112])* $signed(outReVal[2367:2352]) + $signed(y_im[127:112])* $signed(outImVal[2367:2352]);
            corr_re_im[7][0][8] <= $signed(y_re[143:128])* $signed(outReVal[2383:2368]) + $signed(y_im[143:128])* $signed(outImVal[2383:2368]);
            corr_re_im[7][0][9] <= $signed(y_re[159:144])* $signed(outReVal[2399:2384]) + $signed(y_im[159:144])* $signed(outImVal[2399:2384]);
    
            // ========== 状态 7, 输入 1, 10个采样点 ==========
            corr_re_im[7][1][0] <= $signed(y_re[15:0])   * $signed(outReVal[2415:2400]) + $signed(y_im[15:0])   * $signed(outImVal[2415:2400]);
            corr_re_im[7][1][1] <= $signed(y_re[31:16])  * $signed(outReVal[2431:2416]) + $signed(y_im[31:16])  * $signed(outImVal[2431:2416]);
            corr_re_im[7][1][2] <= $signed(y_re[47:32])  * $signed(outReVal[2447:2432]) + $signed(y_im[47:32])  * $signed(outImVal[2447:2432]);
            corr_re_im[7][1][3] <= $signed(y_re[63:48])  * $signed(outReVal[2463:2448]) + $signed(y_im[63:48])  * $signed(outImVal[2463:2448]);
            corr_re_im[7][1][4] <= $signed(y_re[79:64])  * $signed(outReVal[2479:2464]) + $signed(y_im[79:64])  * $signed(outImVal[2479:2464]);
            corr_re_im[7][1][5] <= $signed(y_re[95:80])  * $signed(outReVal[2495:2480]) + $signed(y_im[95:80])  * $signed(outImVal[2495:2480]);
            corr_re_im[7][1][6] <= $signed(y_re[111:96]) * $signed(outReVal[2511:2496]) + $signed(y_im[111:96]) * $signed(outImVal[2511:2496]);
            corr_re_im[7][1][7] <= $signed(y_re[127:112])* $signed(outReVal[2527:2512]) + $signed(y_im[127:112])* $signed(outImVal[2527:2512]);
            corr_re_im[7][1][8] <= $signed(y_re[143:128])* $signed(outReVal[2543:2528]) + $signed(y_im[143:128])* $signed(outImVal[2543:2528]);
            corr_re_im[7][1][9] <= $signed(y_re[159:144])* $signed(outReVal[2559:2544]) + $signed(y_im[159:144])* $signed(outImVal[2559:2544]);
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            tempSum_comb[0][0] <= 16'h0000;
            tempSum_comb[0][1] <= 16'h0000;
            tempSum_comb[1][0] <= 16'h0000;
            tempSum_comb[1][1] <= 16'h0000;
            tempSum_comb[2][0] <= 16'h0000;
            tempSum_comb[2][1] <= 16'h0000;
            tempSum_comb[3][0] <= 16'h0000;
            tempSum_comb[3][1] <= 16'h0000;
            tempSum_comb[4][0] <= 16'h0000;
            tempSum_comb[4][1] <= 16'h0000;
            tempSum_comb[5][0] <= 16'h0000;
            tempSum_comb[5][1] <= 16'h0000;
            tempSum_comb[6][0] <= 16'h0000;
            tempSum_comb[6][1] <= 16'h0000;
            tempSum_comb[7][0] <= 16'h0000;
            tempSum_comb[7][1] <= 16'h0000;
        end
        else if (current_state == ACCUMULATE) begin
        // ===== 状态 0, 输入 0 =====
        tempSum_comb[0][0] = $signed(corr_re_im[0][0][0]) + $signed(corr_re_im[0][0][1]) + 
                             $signed(corr_re_im[0][0][2]) + $signed(corr_re_im[0][0][3]) + 
                             $signed(corr_re_im[0][0][4]) + $signed(corr_re_im[0][0][5]) + 
                             $signed(corr_re_im[0][0][6]) + $signed(corr_re_im[0][0][7]) + 
                             $signed(corr_re_im[0][0][8]) + $signed(corr_re_im[0][0][9]) >>> 15;
        
        // ===== 状态 0, 输入 1 =====
        tempSum_comb[0][1] = $signed(corr_re_im[0][1][0]) + $signed(corr_re_im[0][1][1]) + 
                             $signed(corr_re_im[0][1][2]) + $signed(corr_re_im[0][1][3]) + 
                             $signed(corr_re_im[0][1][4]) + $signed(corr_re_im[0][1][5]) + 
                             $signed(corr_re_im[0][1][6]) + $signed(corr_re_im[0][1][7]) + 
                             $signed(corr_re_im[0][1][8]) + $signed(corr_re_im[0][1][9]) >>> 15;
        
        // ===== 状态 1, 输入 0 =====
        tempSum_comb[1][0] = $signed(corr_re_im[1][0][0]) + $signed(corr_re_im[1][0][1]) + 
                             $signed(corr_re_im[1][0][2]) + $signed(corr_re_im[1][0][3]) + 
                             $signed(corr_re_im[1][0][4]) + $signed(corr_re_im[1][0][5]) + 
                             $signed(corr_re_im[1][0][6]) + $signed(corr_re_im[1][0][7]) + 
                             $signed(corr_re_im[1][0][8]) + $signed(corr_re_im[1][0][9]) >>> 15;
        
        // ===== 状态 1, 输入 1 =====
        tempSum_comb[1][1] = $signed(corr_re_im[1][1][0]) + $signed(corr_re_im[1][1][1]) + 
                             $signed(corr_re_im[1][1][2]) + $signed(corr_re_im[1][1][3]) + 
                             $signed(corr_re_im[1][1][4]) + $signed(corr_re_im[1][1][5]) + 
                             $signed(corr_re_im[1][1][6]) + $signed(corr_re_im[1][1][7]) + 
                             $signed(corr_re_im[1][1][8]) + $signed(corr_re_im[1][1][9]) >>> 15;
        
        // ===== 状态 2, 输入 0 =====
        tempSum_comb[2][0] = $signed(corr_re_im[2][0][0]) + $signed(corr_re_im[2][0][1]) + 
                             $signed(corr_re_im[2][0][2]) + $signed(corr_re_im[2][0][3]) + 
                             $signed(corr_re_im[2][0][4]) + $signed(corr_re_im[2][0][5]) + 
                             $signed(corr_re_im[2][0][6]) + $signed(corr_re_im[2][0][7]) + 
                             $signed(corr_re_im[2][0][8]) + $signed(corr_re_im[2][0][9]) >>> 15;
        
        // ===== 状态 2, 输入 1 =====
        tempSum_comb[2][1] = $signed(corr_re_im[2][1][0]) + $signed(corr_re_im[2][1][1]) + 
                             $signed(corr_re_im[2][1][2]) + $signed(corr_re_im[2][1][3]) + 
                             $signed(corr_re_im[2][1][4]) + $signed(corr_re_im[2][1][5]) + 
                             $signed(corr_re_im[2][1][6]) + $signed(corr_re_im[2][1][7]) + 
                             $signed(corr_re_im[2][1][8]) + $signed(corr_re_im[2][1][9]) >>> 15;
        
        // ===== 状态 3, 输入 0 =====
        tempSum_comb[3][0] = $signed(corr_re_im[3][0][0]) + $signed(corr_re_im[3][0][1]) + 
                             $signed(corr_re_im[3][0][2]) + $signed(corr_re_im[3][0][3]) + 
                             $signed(corr_re_im[3][0][4]) + $signed(corr_re_im[3][0][5]) + 
                             $signed(corr_re_im[3][0][6]) + $signed(corr_re_im[3][0][7]) + 
                             $signed(corr_re_im[3][0][8]) + $signed(corr_re_im[3][0][9]) >>> 15;
        
        // ===== 状态 3, 输入 1 =====
        tempSum_comb[3][1] = $signed(corr_re_im[3][1][0]) + $signed(corr_re_im[3][1][1]) + 
                             $signed(corr_re_im[3][1][2]) + $signed(corr_re_im[3][1][3]) + 
                             $signed(corr_re_im[3][1][4]) + $signed(corr_re_im[3][1][5]) + 
                             $signed(corr_re_im[3][1][6]) + $signed(corr_re_im[3][1][7]) + 
                             $signed(corr_re_im[3][1][8]) + $signed(corr_re_im[3][1][9]) >>> 15;
        
        // ===== 状态 4, 输入 0 =====
        tempSum_comb[4][0] = $signed(corr_re_im[4][0][0]) + $signed(corr_re_im[4][0][1]) + 
                             $signed(corr_re_im[4][0][2]) + $signed(corr_re_im[4][0][3]) + 
                             $signed(corr_re_im[4][0][4]) + $signed(corr_re_im[4][0][5]) + 
                             $signed(corr_re_im[4][0][6]) + $signed(corr_re_im[4][0][7]) + 
                             $signed(corr_re_im[4][0][8]) + $signed(corr_re_im[4][0][9]) >>> 15;
        
        // ===== 状态 4, 输入 1 =====
        tempSum_comb[4][1] = $signed(corr_re_im[4][1][0]) + $signed(corr_re_im[4][1][1]) + 
                             $signed(corr_re_im[4][1][2]) + $signed(corr_re_im[4][1][3]) + 
                             $signed(corr_re_im[4][1][4]) + $signed(corr_re_im[4][1][5]) + 
                             $signed(corr_re_im[4][1][6]) + $signed(corr_re_im[4][1][7]) + 
                             $signed(corr_re_im[4][1][8]) + $signed(corr_re_im[4][1][9]) >>> 15;
        
        // ===== 状态 5, 输入 0 =====
        tempSum_comb[5][0] = $signed(corr_re_im[5][0][0]) + $signed(corr_re_im[5][0][1]) + 
                             $signed(corr_re_im[5][0][2]) + $signed(corr_re_im[5][0][3]) + 
                             $signed(corr_re_im[5][0][4]) + $signed(corr_re_im[5][0][5]) + 
                             $signed(corr_re_im[5][0][6]) + $signed(corr_re_im[5][0][7]) + 
                             $signed(corr_re_im[5][0][8]) + $signed(corr_re_im[5][0][9]) >>> 15;
        
        // ===== 状态 5, 输入 1 =====
        tempSum_comb[5][1] = $signed(corr_re_im[5][1][0]) + $signed(corr_re_im[5][1][1]) + 
                             $signed(corr_re_im[5][1][2]) + $signed(corr_re_im[5][1][3]) + 
                             $signed(corr_re_im[5][1][4]) + $signed(corr_re_im[5][1][5]) + 
                             $signed(corr_re_im[5][1][6]) + $signed(corr_re_im[5][1][7]) + 
                             $signed(corr_re_im[5][1][8]) + $signed(corr_re_im[5][1][9]) >>> 15;
        
        // ===== 状态 6, 输入 0 =====
        tempSum_comb[6][0] = $signed(corr_re_im[6][0][0]) + $signed(corr_re_im[6][0][1]) + 
                             $signed(corr_re_im[6][0][2]) + $signed(corr_re_im[6][0][3]) + 
                             $signed(corr_re_im[6][0][4]) + $signed(corr_re_im[6][0][5]) + 
                             $signed(corr_re_im[6][0][6]) + $signed(corr_re_im[6][0][7]) + 
                             $signed(corr_re_im[6][0][8]) + $signed(corr_re_im[6][0][9]) >>> 15;
        
        // ===== 状态 6, 输入 1 =====
        tempSum_comb[6][1] = $signed(corr_re_im[6][1][0]) + $signed(corr_re_im[6][1][1]) + 
                             $signed(corr_re_im[6][1][2]) + $signed(corr_re_im[6][1][3]) + 
                             $signed(corr_re_im[6][1][4]) + $signed(corr_re_im[6][1][5]) + 
                             $signed(corr_re_im[6][1][6]) + $signed(corr_re_im[6][1][7]) + 
                             $signed(corr_re_im[6][1][8]) + $signed(corr_re_im[6][1][9]) >>> 15;
        
        // ===== 状态 7, 输入 0 =====
        tempSum_comb[7][0] = $signed(corr_re_im[7][0][0]) + $signed(corr_re_im[7][0][1]) + 
                             $signed(corr_re_im[7][0][2]) + $signed(corr_re_im[7][0][3]) + 
                             $signed(corr_re_im[7][0][4]) + $signed(corr_re_im[7][0][5]) + 
                             $signed(corr_re_im[7][0][6]) + $signed(corr_re_im[7][0][7]) + 
                             $signed(corr_re_im[7][0][8]) + $signed(corr_re_im[7][0][9]) >>> 15;
        
        // ===== 状态 7, 输入 1 =====
        tempSum_comb[7][1] = $signed(corr_re_im[7][1][0]) + $signed(corr_re_im[7][1][1]) + 
                             $signed(corr_re_im[7][1][2]) + $signed(corr_re_im[7][1][3]) + 
                             $signed(corr_re_im[7][1][4]) + $signed(corr_re_im[7][1][5]) + 
                             $signed(corr_re_im[7][1][6]) + $signed(corr_re_im[7][1][7]) + 
                             $signed(corr_re_im[7][1][8]) + $signed(corr_re_im[7][1][9]) >>> 15;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tempSum[0][0] <= 33'h0000;
            tempSum[0][1] <= 33'h0000;
            tempSum[1][0] <= 33'h0000;
            tempSum[1][1] <= 33'h0000;
            tempSum[2][0] <= 33'h0000;
            tempSum[2][1] <= 33'h0000;
            tempSum[3][0] <= 33'h0000;
            tempSum[3][1] <= 33'h0000;
            tempSum[4][0] <= 33'h0000;
            tempSum[4][1] <= 33'h0000;
            tempSum[5][0] <= 33'h0000;
            tempSum[5][1] <= 33'h0000;
            tempSum[6][0] <= 33'h0000;
            tempSum[6][1] <= 33'h0000;
            tempSum[7][0] <= 33'h0000;
            tempSum[7][1] <= 33'h0000;
        end else if (current_state == UPDATE_tempSum) begin
           tempSum[0][0] <= $signed(Lc) * $signed(tempSum_comb[0][0][15:0]);
           tempSum[0][1] <= $signed(Lc) * $signed(tempSum_comb[0][1][15:0]);
           tempSum[1][0] <= $signed(Lc) * $signed(tempSum_comb[1][0][15:0]);
           tempSum[1][1] <= $signed(Lc) * $signed(tempSum_comb[1][1][15:0]);
           tempSum[2][0] <= $signed(Lc) * $signed(tempSum_comb[2][0][15:0]);
           tempSum[2][1] <= $signed(Lc) * $signed(tempSum_comb[2][1][15:0]);
           tempSum[3][0] <= $signed(Lc) * $signed(tempSum_comb[3][0][15:0]);
           tempSum[3][1] <= $signed(Lc) * $signed(tempSum_comb[3][1][15:0]);
           tempSum[4][0] <= $signed(Lc) * $signed(tempSum_comb[4][0][15:0]);
           tempSum[4][1] <= $signed(Lc) * $signed(tempSum_comb[4][1][15:0]);
           tempSum[5][0] <= $signed(Lc) * $signed(tempSum_comb[5][0][15:0]);
           tempSum[5][1] <= $signed(Lc) * $signed(tempSum_comb[5][1][15:0]);
           tempSum[6][0] <= $signed(Lc) * $signed(tempSum_comb[6][0][15:0]);
           tempSum[6][1] <= $signed(Lc) * $signed(tempSum_comb[6][1][15:0]);
           tempSum[7][0] <= $signed(Lc) * $signed(tempSum_comb[7][0][15:0]);
           tempSum[7][1] <= $signed(Lc) * $signed(tempSum_comb[7][1][15:0]);
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            gamma_input_0 <= 128'b0;
            gamma_input_1 <= 128'b0;
            gamma <= 256'b0;
            calc_done <= 1'b0;
        end 
        else if (current_state == UPDATE_GAMMA) begin//数据变成了Q11，4结构
            gamma[15:0]    <= tempSum[0][0][16:1];  // gamma[0]
            gamma[31:16]   <= tempSum[0][1][16:1];  // gamma[1]
            gamma[47:32]   <= tempSum[1][0][16:1];  // gamma[2]
            gamma[63:48]   <= tempSum[1][1][16:1];  // gamma[3]
            gamma[79:64]   <= tempSum[2][0][16:1];  // gamma[4]
            gamma[95:80]   <= tempSum[2][1][16:1];  // gamma[5]
            gamma[111:96]  <= tempSum[3][0][16:1];  // gamma[6]
            gamma[127:112] <= tempSum[3][1][16:1];  // gamma[7]
            gamma[143:128] <= tempSum[4][0][16:1];  // gamma[8]
            gamma[159:144] <= tempSum[4][1][16:1];  // gamma[9]
            gamma[175:160] <= tempSum[5][0][16:1];  // gamma[10]
            gamma[191:176] <= tempSum[5][1][16:1];  // gamma[11]
            gamma[207:192] <= tempSum[6][0][16:1];  // gamma[12]
            gamma[223:208] <= tempSum[6][1][16:1];  // gamma[13]
            gamma[239:224] <= tempSum[7][0][16:1];  // gamma[14]
            gamma[255:240] <= tempSum[7][1][16:1];  // gamma[15]
            
                // tempSum是16位Q6.9有符号数，格式：1位符号位 + 6位整数 + 9位小数
                // 只取整数部分[15:10]，并进行符号扩展到16位
            // 统一修改Q11，4结构
            gamma_input_0[6 * 16 +: 16] <= sat_add16($signed(tempSum[0][0][16:1]), $signed(alpha_2[0 * 16 +: 16]));
            gamma_input_0[7 * 16 +: 16] <= sat_add16($signed(tempSum[0][1][16:1]), $signed(alpha_2[0 * 16 +: 16]));
            gamma_input_0[2 * 16 +: 16] <= sat_add16($signed(tempSum[1][0][16:1]), $signed(alpha_2[1 * 16 +: 16]));
            gamma_input_0[3 * 16 +: 16] <= sat_add16($signed(tempSum[1][1][16:1]), $signed(alpha_2[1 * 16 +: 16]));
            gamma_input_0[0 * 16 +: 16] <= sat_add16($signed(tempSum[2][0][16:1]), $signed(alpha_2[2 * 16 +: 16]));
            gamma_input_0[1 * 16 +: 16] <= sat_add16($signed(tempSum[2][1][16:1]), $signed(alpha_2[2 * 16 +: 16]));
            gamma_input_0[4 * 16 +: 16] <= sat_add16($signed(tempSum[3][0][16:1]), $signed(alpha_2[3 * 16 +: 16]));
            gamma_input_0[5 * 16 +: 16] <= sat_add16($signed(tempSum[3][1][16:1]), $signed(alpha_2[3 * 16 +: 16]));
           
            gamma_input_1[2 * 16 +: 16] <= sat_add16($signed(tempSum[4][0][16:1]), $signed(alpha_2[4 * 16 +: 16]));
            gamma_input_1[3 * 16 +: 16] <= sat_add16($signed(tempSum[4][1][16:1]), $signed(alpha_2[4 * 16 +: 16]));
            gamma_input_1[6 * 16 +: 16] <= sat_add16($signed(tempSum[5][0][16:1]), $signed(alpha_2[5 * 16 +: 16]));
            gamma_input_1[7 * 16 +: 16] <= sat_add16($signed(tempSum[5][1][16:1]), $signed(alpha_2[5 * 16 +: 16]));
            gamma_input_1[4 * 16 +: 16] <= sat_add16($signed(tempSum[6][0][16:1]), $signed(alpha_2[6 * 16 +: 16]));
            gamma_input_1[5 * 16 +: 16] <= sat_add16($signed(tempSum[6][1][16:1]), $signed(alpha_2[6 * 16 +: 16]));
            gamma_input_1[0 * 16 +: 16] <= sat_add16($signed(tempSum[7][0][16:1]), $signed(alpha_2[7 * 16 +: 16]));
            gamma_input_1[1 * 16 +: 16] <= sat_add16($signed(tempSum[7][1][16:1]), $signed(alpha_2[7 * 16 +: 16]));

            calc_done <= 1;         
        end
        else if (current_state == DONE) begin
            calc_done <= 0;
        end
    end
    
endmodule
