`timescale 1ns / 1ps

module top (
input clk, rst, 
input [127:0] plaintext, key,
output reg [127:0] state, ciphertext
);


// Round keys
wire [127:0] round_key [10:0];
wire [127:0] current_key [0:10];
                 

keyExpansion KE (
.key_i(key),
.round_key_1(current_key[0]),   .round_key_2(current_key[1]),   .round_key_3(current_key[2]),   .round_key_4(current_key[3]),
.round_key_5(current_key[4]),   .round_key_6(current_key[5]),   .round_key_7(current_key[6]),   .round_key_8(current_key[7]),   
.round_key_9(current_key[8]),   .round_key_10(current_key[9]), .round_key_11(current_key[10])
);

//FSM state registers
reg [127:0] aes_state;
reg [3:0] roundNo;
 


// Update state registers
always @(posedge clk or posedge rst)
begin 
    if (rst) 
    begin 
        aes_state <= plaintext;   //no need to assign key cause round 0 ki current_key is already decided in the kry expansion module 
        roundNo <= 4'd0;          // Round - 0 : Initial transformation
    end
    
    else 
    begin
        aes_state <= round_function( roundNo, aes_state, sb_out, sr_out, mc_out, current_key[roundNo] );
        roundNo <= roundNo +1;    // Round - 1 to Round - 10 
    end 
end 

//Next state logic
function [127:0] round_function (
input [3:0]   round_num,
input [127:0] state_in,
input [127:0] sb_out,
input [127:0] sr_out,
input [127:0] mc_out,
input [127:0] round_key
);
begin 
    if (round_num ==0) // Initial Tranformation
    begin
         round_function = state_in ^ round_key;
    end 
    
    else if (round_num <10) // Round 1 - 9
    begin 
        round_function = mc_out ^ round_key;
    end 
    
    else if ( round_num == 10) // Last Round (Round 10)
    begin 
        round_function = sr_out ^ round_key;
    end     
    
    else
    begin 
        round_function = 128'h0;
    end 
end 
endfunction

//Evaluate output (Ciphertext) 
always @ (posedge clk)
begin 
    if (roundNo == 11) ciphertext <= aes_state; 
    else state <= aes_state; // To display states at the beginning of each round 
end 



//Round computations 
wire [127:0] sb_out;
wire [127:0] sr_out;
wire [127:0] mc_out;

subByte SB (
.subByte_i(aes_state),
.subByte_o(sb_out)
);

shiftRow SR (
.shiftRow_i(sb_out),
.shiftRow_o(sr_out)
);

mixColumn MC (
.mixCol_i(sr_out),
.mixCol_o(mc_out)
);


endmodule 


module keyExpansion (
input [127:0] key_i,
output [127:0] round_key_1,  round_key_2,  round_key_3,  round_key_4,  round_key_5,  
               round_key_6,  round_key_7,  round_key_8,  round_key_9, round_key_10, round_key_11
);

parameter nb = 4; //block size = 4 (=4*32 bits) ---> fixed
parameter nr = 10; // no of rounds
parameter key_length = 44; // nb*(nr+1) = 4*(10+1)

wire [31:0] w [key_length  :1];
wire [31:0] w_temp [key_length  :1];
wire [31:0] w_xor [key_length  :1];

wire [31:0] round_key_temp [key_length  :1];

wire [31:0] rootWord_in [key_length  :1];
wire [31:0] rootWord_out [key_length  :1];
wire [31:0] subWord_in [key_length  :1];
wire [31:0] subWord_out [key_length  :1];
wire [7:0] rcon_in [key_length  :1];
wire [7:0] rcon_out [key_length  :1];

// initial tranformation uses key_i (input key) directly
//assign w[key_length -1] = key_i[127: 96] ; //w[10]


assign w[44] = key_i[127 : 96] ;
assign w[43] = key_i[95 : 64] ;
assign w[42] = key_i[63 : 32] ;
assign w[41] = key_i[31 : 0] ; 

assign round_key_temp[44] = w[44];
assign round_key_temp[43] = w[43];
assign round_key_temp[42] = w[42];
assign round_key_temp[41] = w[41];


genvar x;
generate
for (x=40; x>=1; x=x-1) begin : GEN_W
    assign w_temp[x] = w[x+1];
end
endgenerate


genvar j;
generate
for (j=40 ; j>=1 ; j=j-1)
begin 
   if(j%4 ==0)
   begin
        assign rootWord_in[j] =  w_temp[j];
 
        rootWord instance1 ( .in(rootWord_in[j]), .out(rootWord_out[j]));
        assign subWord_in[j] = rootWord_out[j];
 
        subWord instance2 ( .in(subWord_in[j]), .out(subWord_out[j]) );
        assign rcon_in[j] = subWord_out[j][31:24];
 
        rcon_xor instance3 ( .k(11-(j/4)), .in(rcon_in[j]), .out(rcon_out[j]) );
        assign w_xor[j] = { rcon_out[j] , subWord_out[j][23:0] };
 
        assign w[j] = w[j+4] ^ w_xor[j]; //assign w[j] = w[j-4] ^ w_xor[j];
      
        assign round_key_temp[j] = w[j];
    end 

    else 
    begin 
            assign w[j] = w[j+4] ^ w[j+1];
            assign round_key_temp[j] = w[j];
    end
end 
endgenerate    


assign round_key_1  = { round_key_temp[44], round_key_temp[43], round_key_temp[42], round_key_temp[41] };
assign round_key_2  = { round_key_temp[40], round_key_temp[39], round_key_temp[38], round_key_temp[37] };
assign round_key_3  = { round_key_temp[36], round_key_temp[35], round_key_temp[34], round_key_temp[33] };
assign round_key_4  = { round_key_temp[32], round_key_temp[31], round_key_temp[30], round_key_temp[29] };
assign round_key_5  = { round_key_temp[28], round_key_temp[27], round_key_temp[26], round_key_temp[25] };
assign round_key_6  = { round_key_temp[24], round_key_temp[23], round_key_temp[22], round_key_temp[21] };
assign round_key_7  = { round_key_temp[20], round_key_temp[19], round_key_temp[18], round_key_temp[17] };
assign round_key_8  = { round_key_temp[16], round_key_temp[15], round_key_temp[14], round_key_temp[13] };
assign round_key_9  = { round_key_temp[12], round_key_temp[11], round_key_temp[10], round_key_temp[9]  };
assign round_key_10 = { round_key_temp[8],  round_key_temp[7],  round_key_temp[6],  round_key_temp[5]  };
assign round_key_11 = { round_key_temp[4],  round_key_temp[3],  round_key_temp[2],  round_key_temp[1]  };

endmodule


module rootWord ( input [31:0] in, output [31:0] out);
// performs 1 cyclic left Shift 
begin 
assign out[31:24] = in [23:16];
assign out[23:16] = in [15:8];
assign out[15:8] = in [7:0];
assign out[7:0] = in [31:24];
end 
endmodule 

module subWord ( input [31:0] in, output [31:0] out );
// sbox substituion 
begin 
wire [31:0] out_temp;
SBox dut (.data_i(in), .sbox_o(out_temp));
assign out = out_temp;
end 
endmodule

module rcon_xor ( input [3:0]k, input [7:0] in, output [7:0] out);

reg  [7:0] rcon_value;
always @(*) begin
  case (k)
    4'd1: rcon_value = 8'h01;
    4'd2: rcon_value = 8'h02;
    4'd3: rcon_value = 8'h04;
    4'd4: rcon_value = 8'h08;
    4'd5: rcon_value = 8'h10;
    4'd6: rcon_value = 8'h20;
    4'd7: rcon_value = 8'h40;
    4'd8: rcon_value = 8'h80;
    4'd9: rcon_value = 8'h1b;
    4'd10: rcon_value = 8'h36;
    default: rcon_value = 8'h00;
  endcase
end 
assign out = in ^ rcon_value; 
endmodule 

module SBox (
 input wire [127:0] data_i, 
 output wire [127:0] sbox_o 
 );


wire [7:0] a [15:0] ;   // [length] a [number of.]
reg [7:0] c [15:0] ;

genvar i;
generate 
for (i=0;i<16; i=i+1) 
    begin
    assign a[i]= data_i[i*8+7 : i*8];
    end
endgenerate

generate 
for (i=0;i<16; i=i+1) 
    begin
    assign sbox_o[i*8+7 : i*8]= c[i];
    end
endgenerate

integer j;

always @(*) 
    begin
    for (j = 0; j < 16; j = j + 1) 
    begin
    case (a[j])
      8'h00: c[j] = 8'h63;
      8'h01: c[j] = 8'h7c;
      8'h02: c[j] = 8'h77;
      8'h03: c[j] = 8'h7b;
      8'h04: c[j] = 8'hf2;
      8'h05: c[j] = 8'h6b;
      8'h06: c[j] = 8'h6f;
      8'h07: c[j] = 8'hc5;
      8'h08: c[j] = 8'h30;
      8'h09: c[j] = 8'h01;
      8'h0a: c[j] = 8'h67;
      8'h0b: c[j] = 8'h2b;
      8'h0c: c[j] = 8'hfe;
      8'h0d: c[j] = 8'hd7;
      8'h0e: c[j] = 8'hab;
      8'h0f: c[j] = 8'h76;
      8'h10: c[j] = 8'hca;
      8'h11: c[j] = 8'h82;
      8'h12: c[j] = 8'hc9;
      8'h13: c[j] = 8'h7d;
      8'h14: c[j] = 8'hfa;
      8'h15: c[j] = 8'h59;
      8'h16: c[j] = 8'h47;
      8'h17: c[j] = 8'hf0;
      8'h18: c[j] = 8'had;
      8'h19: c[j] = 8'hd4;
      8'h1a: c[j] = 8'ha2;
      8'h1b: c[j] = 8'haf;
      8'h1c: c[j] = 8'h9c;
      8'h1d: c[j] = 8'ha4;
      8'h1e: c[j] = 8'h72;
      8'h1f: c[j] = 8'hc0;
	  8'h20: c[j]=8'hb7;
	  8'h21: c[j]=8'hfd;
      8'h22: c[j]=8'h93;
8'h23: c[j]=8'h26;
8'h24: c[j]=8'h36;
8'h25: c[j]=8'h3f;
8'h26: c[j]=8'hf7;
8'h27: c[j]=8'hcc;
8'h28: c[j]=8'h34;
8'h29: c[j]=8'ha5;
8'h2a: c[j]=8'he5;
8'h2b: c[j]=8'hf1;
8'h2c: c[j]=8'h71;
8'h2d: c[j]=8'hd8;
8'h2e: c[j]=8'h31;
8'h2f: c[j]=8'h15;
8'h30: c[j]=8'h04;
8'h31: c[j]=8'hc7;
8'h32: c[j]=8'h23;
8'h33: c[j]=8'hc3;
8'h34: c[j]=8'h18;
8'h35: c[j]=8'h96;
8'h36: c[j]=8'h05;
8'h37: c[j]=8'h9a;
8'h38: c[j]=8'h07;
8'h39: c[j]=8'h12;
8'h3a: c[j]=8'h80;
8'h3b: c[j]=8'he2;
8'h3c: c[j]=8'heb;
8'h3d: c[j]=8'h27;
8'h3e: c[j]=8'hb2;
8'h3f: c[j]=8'h75;
8'h40: c[j]=8'h09;
8'h41: c[j]=8'h83;
8'h42: c[j]=8'h2c;
8'h43: c[j]=8'h1a;
8'h44: c[j]=8'h1b;
8'h45: c[j]=8'h6e;
8'h46: c[j]=8'h5a;
8'h47: c[j]=8'ha0;
8'h48: c[j]=8'h52;
8'h49: c[j]=8'h3b;
8'h4a: c[j]=8'hd6;
8'h4b: c[j]=8'hb3;
8'h4c: c[j]=8'h29;
8'h4d: c[j]=8'he3;
8'h4e: c[j]=8'h2f;
8'h4f: c[j]=8'h84;
8'h50: c[j]=8'h53;
8'h51: c[j]=8'hd1;
8'h52: c[j]=8'h00;
8'h53: c[j]=8'hed;
8'h54: c[j]=8'h20;
8'h55: c[j]=8'hfc;
8'h56: c[j]=8'hb1;
8'h57: c[j]=8'h5b;
8'h58: c[j]=8'h6a;
8'h59: c[j]=8'hcb;
8'h5a: c[j]=8'hbe;
8'h5b: c[j]=8'h39;
8'h5c: c[j]=8'h4a;
8'h5d: c[j]=8'h4c;
8'h5e: c[j]=8'h58;
8'h5f: c[j]=8'hcf;
8'h60: c[j]=8'hd0;
8'h61: c[j]=8'hef;
8'h62: c[j]=8'haa;
8'h63: c[j]=8'hfb;
8'h64: c[j]=8'h43;
8'h65: c[j]=8'h4d;
8'h66: c[j]=8'h33;
8'h67: c[j]=8'h85;
8'h68: c[j]=8'h45;
8'h69: c[j]=8'hf9;
8'h6a: c[j]=8'h02;
8'h6b: c[j]=8'h7f;
8'h6c: c[j]=8'h50;
8'h6d: c[j]=8'h3c;
8'h6e: c[j]=8'h9f;
8'h6f: c[j]=8'ha8;
8'h70: c[j]=8'h51;
8'h71: c[j]=8'ha3;
8'h72: c[j]=8'h40;
8'h73: c[j]=8'h8f;
8'h74: c[j]=8'h92;
8'h75: c[j]=8'h9d;
8'h76: c[j]=8'h38;
8'h77: c[j]=8'hf5;
8'h78: c[j]=8'hbc;
8'h79: c[j]=8'hb6;
8'h7a: c[j]=8'hda;
8'h7b: c[j]=8'h21;
8'h7c: c[j]=8'h10;
8'h7d: c[j]=8'hff;
8'h7e: c[j]=8'hf3;
8'h7f: c[j]=8'hd2;
8'h80: c[j]=8'hcd;
8'h81: c[j]=8'h0c;
8'h82: c[j]=8'h13;
8'h83: c[j]=8'hec;
8'h84: c[j]=8'h5f;
8'h85: c[j]=8'h97;
8'h86: c[j]=8'h44;
8'h87: c[j]=8'h17;
8'h88: c[j]=8'hc4;
8'h89: c[j]=8'ha7;
8'h8a: c[j]=8'h7e;
8'h8b: c[j]=8'h3d;
8'h8c: c[j]=8'h64;
8'h8d: c[j]=8'h5d;
8'h8e: c[j]=8'h19;
8'h8f: c[j]=8'h73;
8'h90: c[j]=8'h60;
8'h91: c[j]=8'h81;
8'h92: c[j]=8'h4f;
8'h93: c[j]=8'hdc;
8'h94: c[j]=8'h22;
8'h95: c[j]=8'h2a;
8'h96: c[j]=8'h90;
8'h97: c[j]=8'h88;
8'h98: c[j]=8'h46;
8'h99: c[j]=8'hee;
8'h9a: c[j]=8'hb8;
8'h9b: c[j]=8'h14;
8'h9c: c[j]=8'hde;
8'h9d: c[j]=8'h5e;
8'h9e: c[j]=8'h0b;
8'h9f: c[j]=8'hdb;
8'ha0: c[j]=8'he0;
8'ha1: c[j]=8'h32;
8'ha2: c[j]=8'h3a;
8'ha3: c[j]=8'h0a;
8'ha4: c[j]=8'h49;
8'ha5: c[j]=8'h06;
8'ha6: c[j]=8'h24;
8'ha7: c[j]=8'h5c;
8'ha8: c[j]=8'hc2;
8'ha9: c[j]=8'hd3;
8'haa: c[j]=8'hac;
8'hab: c[j]=8'h62;
8'hac: c[j]=8'h91;
8'had: c[j]=8'h95;
8'hae: c[j]=8'he4;
8'haf: c[j]=8'h79;
8'hb0: c[j]=8'he7;
8'hb1: c[j]=8'hc8;
8'hb2: c[j]=8'h37;
8'hb3: c[j]=8'h6d;
8'hb4: c[j]=8'h8d;
8'hb5: c[j]=8'hd5;
8'hb6: c[j]=8'h4e;
8'hb7: c[j]=8'ha9;
8'hb8: c[j]=8'h6c;
8'hb9: c[j]=8'h56;
8'hba: c[j]=8'hf4;
8'hbb: c[j]=8'hea;
8'hbc: c[j]=8'h65;
8'hbd: c[j]=8'h7a;
8'hbe: c[j]=8'hae;
8'hbf: c[j]=8'h08;
8'hc0: c[j]=8'hba;
8'hc1: c[j]=8'h78;
8'hc2: c[j]=8'h25;
8'hc3: c[j]=8'h2e;
8'hc4: c[j]=8'h1c;
8'hc5: c[j]=8'ha6;
8'hc6: c[j]=8'hb4;
8'hc7: c[j]=8'hc6;
8'hc8: c[j]=8'he8;
8'hc9: c[j]=8'hdd;
8'hca: c[j]=8'h74;
8'hcb: c[j]=8'h1f;
8'hcc: c[j]=8'h4b;
8'hcd: c[j]=8'hbd;
8'hce: c[j]=8'h8b;
	   8'hcf: c[j]=8'h8a;
	   8'hd0: c[j]=8'h70;
	   8'hd1: c[j]=8'h3e;
	   8'hd2: c[j]=8'hb5;
	   8'hd3: c[j]=8'h66;
	   8'hd4: c[j]=8'h48;
	   8'hd5: c[j]=8'h03;
	   8'hd6: c[j]=8'hf6;
	   8'hd7: c[j]=8'h0e;
	   8'hd8: c[j]=8'h61;
	   8'hd9: c[j]=8'h35;
	   8'hda: c[j]=8'h57;
	   8'hdb: c[j]=8'hb9;
	   8'hdc: c[j]=8'h86;
	   8'hdd: c[j]=8'hc1;
	   8'hde: c[j]=8'h1d;
	   8'hdf: c[j]=8'h9e;
	   8'he0: c[j]=8'he1;
	   8'he1: c[j]=8'hf8;
	   8'he2: c[j]=8'h98;
	   8'he3: c[j]=8'h11;
	   8'he4: c[j]=8'h69;
	   8'he5: c[j]=8'hd9;
	   8'he6: c[j]=8'h8e;
	   8'he7: c[j]=8'h94;
	   8'he8: c[j]=8'h9b;
	   8'he9: c[j]=8'h1e;
	   8'hea: c[j]=8'h87;
	   8'heb: c[j]=8'he9;
	   8'hec: c[j]=8'hce;
	   8'hed: c[j]=8'h55;
	   8'hee: c[j]=8'h28;
	   8'hef: c[j]=8'hdf;
	   8'hf0: c[j]=8'h8c;
	   8'hf1: c[j]=8'ha1;
	   8'hf2: c[j]=8'h89;
	   8'hf3: c[j]=8'h0d;
	   8'hf4: c[j]=8'hbf;
	   8'hf5: c[j]=8'he6;
	   8'hf6: c[j]=8'h42;
	   8'hf7: c[j]=8'h68;
	   8'hf8: c[j]=8'h41;
	   8'hf9: c[j]=8'h99;
	   8'hfa: c[j]=8'h2d;
	   8'hfb: c[j]=8'h0f;
	   8'hfc: c[j]=8'hb0;
	   8'hfd: c[j]=8'h54;
	   8'hfe: c[j]=8'hbb;
	   8'hff: c[j]=8'h16;
    endcase
  end
end
endmodule 


module subByte (
input [127:0] subByte_i,
output [127:0] subByte_o
);

SBox dut (.data_i(subByte_i), .sbox_o(subByte_o));

endmodule

module shiftRow (
input [127:0] shiftRow_i,
output [127:0] shiftRow_o
);

wire [31:0] subByte_row [3:0];
wire [31:0] shiftRow_row [3:0];
    
// break 128-bit block inot 4rows of 32-bit 
genvar sr;
generate
for (sr = 3; sr >= 0; sr = sr - 1)
begin
        assign subByte_row[sr] = { shiftRow_i[3*32+8*sr+7:3*32+8*sr],
                                   shiftRow_i[2*32+8*sr+7:2*32+8*sr],
                                   shiftRow_i[32+8*sr+7:32+8*sr],                                   
                                   shiftRow_i[8*sr+7:8*sr] 
                                    };
//    subByte_row[0] -> bottom row   
//    subByte_row[3] -> top row                            
end
endgenerate
    
// cyclic LShift					       
assign shiftRow_row[3] = subByte_row[3];
assign shiftRow_row[2] = { subByte_row[2][23:16], subByte_row[2][15:8], subByte_row[2][7:0], subByte_row[2][31:24] };
assign shiftRow_row[1] = { subByte_row[1][15:8], subByte_row[1][7:0], subByte_row[1][31:24], subByte_row[1][23:16] };
assign shiftRow_row[0] = { subByte_row[0][7:0], subByte_row[0][31:24], subByte_row[0][23:16], subByte_row[0][15:8] };

genvar sr_r;
generate
for (sr_r = 3; sr_r >= 0; sr_r = sr_r - 1)
begin
        assign {shiftRow_o[3*32+8*sr_r+7:3*32+8*sr_r],
                shiftRow_o[2*32+8*sr_r+7:2*32+8*sr_r],
                shiftRow_o[32+8*sr_r+7:32+8*sr_r],
                shiftRow_o[8*sr_r+7:8*sr_r] } = shiftRow_row[sr_r];
end
endgenerate

endmodule

module galiosMul2 (
input [7:0]in,
output [7:0] out
);

//galois field multiplication with 2 = multiplication with polynomial x
// if bit7 = 0, the result is already reduced i.e it doenst contain any power >7
// if bit7 = 1, the reusult must be reduced by multiplying the polynomial with 8'h1b -> multiplying is equivalent to ! left shift, followed by XOR with 8'h1b
assign out = (in[7]) ? ({in[6:0],1'b0} ^ 8'h1b) : {in[6:0],1'b0};

endmodule
module galiosMul3 (
input [7:0]in,
output [7:0] out
);

wire [7:0] out1;

assign out1 = (in[7]) ? ({in[6:0],1'b0} ^ 8'h1b) : {in[6:0],1'b0};
assign out =  out1 ^ in;
endmodule

module mixColumn (
input [127:0] mixCol_i,
output [127:0] mixCol_o
);

wire [31:0] shiftRow_col [3:0];
wire [31:0] mixCol_col [3:0]; 

// mixCol_col 0
wire [7:0] gm2_00, gm3_00, gm2_10, gm3_10, gm2_20, gm3_20, gm2_30, gm3_30;
// mixCol_col 1
wire [7:0] gm2_01, gm3_01, gm2_11, gm3_11, gm2_21, gm3_21, gm2_31, gm3_31;    
// mixCol_col 2
wire [7:0] gm2_02, gm3_02, gm2_12, gm3_12, gm2_22, gm3_22, gm2_32, gm3_32;
// mixCol_col 3
wire [7:0] gm2_03, gm3_03, gm2_13, gm3_13, gm2_23, gm3_23, gm2_33, gm3_33;
 
// break 128-bit block inot 4 columns of 32-bit 
genvar mc;
generate 
for (mc = 3 ; mc>=0 ; mc=mc-1)
    begin 
    assign shiftRow_col[mc] = mixCol_i[32*mc+31 :32*mc] ;
        
    //     shiftRow_col[0] -> last col
    //     shiftRow_colw[3] -> first col                           
    end
endgenerate


// mixColum [0] -> last col
galiosMul2 inst_name1 (.in(shiftRow_col[0][31 : 24]), .out(gm2_00) );
galiosMul3 inst_name2 (.in(shiftRow_col[0][23 : 16]), .out(gm3_00) );
assign mixCol_col[0][31:24] = gm2_00 ^ gm3_00 ^ shiftRow_col[0][15 : 8] ^ shiftRow_col[0][7 : 0] ; 

galiosMul2 inst_name3 (.in(shiftRow_col[0][23 : 16]), .out(gm2_10) );
galiosMul3 inst_name4 (.in(shiftRow_col[0][15 : 8]), .out(gm3_10) );
assign mixCol_col[0][23:16] = gm2_10 ^ gm3_10 ^ shiftRow_col[0][31 : 24] ^ shiftRow_col[0][7 : 0] ; 

galiosMul2 inst_name5 (.in(shiftRow_col[0][15 : 8]), .out(gm2_20) );
galiosMul3 inst_name6 (.in(shiftRow_col[0][7 : 0]), .out(gm3_20) );
assign mixCol_col[0][15:8] = gm2_20 ^ gm3_20 ^ shiftRow_col[0][31 : 24] ^ shiftRow_col[0][23 : 16] ; 

galiosMul2 inst_name7 (.in(shiftRow_col[0][7 : 0]), .out(gm2_30) );
galiosMul3 inst_name8 (.in(shiftRow_col[0][31 : 24]), .out(gm3_30) );
assign mixCol_col[0][7:0] = gm2_30 ^ gm3_30 ^ shiftRow_col[0][23 : 16] ^ shiftRow_col[0][15 : 8] ; 

/////////////////////////////////////////////////////
// mixColum [1] 

galiosMul2 inst_name11 (.in(shiftRow_col[1][31 : 24]), .out(gm2_01) );
galiosMul3 inst_name21 (.in(shiftRow_col[1][23 : 16]), .out(gm3_01) );
assign mixCol_col[1][31:24] = gm2_01 ^ gm3_01 ^ shiftRow_col[1][15 : 8] ^ shiftRow_col[1][7 : 0] ; 

galiosMul2 inst_name31 (.in(shiftRow_col[1][23 : 16]), .out(gm2_11) );
galiosMul3 inst_name41 (.in(shiftRow_col[1][15 : 8]), .out(gm3_11) );
assign mixCol_col[1][23:16] = gm2_11 ^ gm3_11 ^ shiftRow_col[1][31 : 24] ^ shiftRow_col[1][7 : 0] ; 

galiosMul2 inst_name51 (.in(shiftRow_col[1][15 : 8]), .out(gm2_21) );
galiosMul3 inst_name61 (.in(shiftRow_col[1][7 : 0]), .out(gm3_21) );
assign mixCol_col[1][15:8] = gm2_21 ^ gm3_21 ^ shiftRow_col[1][31 : 24] ^ shiftRow_col[1][23 : 16] ; 

galiosMul2 inst_name71 (.in(shiftRow_col[1][7 : 0]), .out(gm2_31) );
galiosMul3 inst_name81 (.in(shiftRow_col[1][31 : 24]), .out(gm3_31) );
assign mixCol_col[1][7:0] = gm2_31 ^ gm3_31 ^ shiftRow_col[1][23 : 16] ^ shiftRow_col[1][15 : 8] ; 

/////////////////////////////////////////////////////
// mixColum [2] 

galiosMul2 inst_name12 (.in(shiftRow_col[2][31 : 24]), .out(gm2_02) );
galiosMul3 inst_name22 (.in(shiftRow_col[2][23 : 16]), .out(gm3_02) );
assign mixCol_col[2][31:24] = gm2_02 ^ gm3_02 ^ shiftRow_col[2][15 : 8] ^ shiftRow_col[2][7 : 0] ; 

galiosMul2 inst_name32 (.in(shiftRow_col[2][23 : 16]), .out(gm2_12) );
galiosMul3 inst_name42 (.in(shiftRow_col[2][15 : 8]), .out(gm3_12) );
assign mixCol_col[2][23:16] = gm2_12 ^ gm3_12 ^ shiftRow_col[2][31 : 24] ^ shiftRow_col[2][7 : 0] ; 

galiosMul2 inst_name52 (.in(shiftRow_col[2][15 : 8]), .out(gm2_22) );
galiosMul3 inst_name62 (.in(shiftRow_col[2][7 : 0]), .out(gm3_22) );
assign mixCol_col[2][15:8] = gm2_22 ^ gm3_22 ^ shiftRow_col[2][31 : 24] ^ shiftRow_col[2][23 : 16] ; 

galiosMul2 inst_name72 (.in(shiftRow_col[2][7 : 0]), .out(gm2_32) );
galiosMul3 inst_name82 (.in(shiftRow_col[2][31 : 24]), .out(gm3_32) );
assign mixCol_col[2][7:0] = gm2_32 ^ gm3_32 ^ shiftRow_col[2][23 : 16] ^ shiftRow_col[2][15 : 8] ; 

/////////////////////////////////////////////////////
// mixColum [3] -> first col 

galiosMul2 inst_name13 (.in(shiftRow_col[3][31 : 24]), .out(gm2_03) );
galiosMul3 inst_name23 (.in(shiftRow_col[3][23 : 16]), .out(gm3_03) );
assign mixCol_col[3][31:24] = gm2_03 ^ gm3_03 ^ shiftRow_col[3][15 : 8] ^ shiftRow_col[3][7 : 0] ; 

galiosMul2 inst_name33 (.in(shiftRow_col[3][23 : 16]), .out(gm2_13) );
galiosMul3 inst_name43 (.in(shiftRow_col[3][15 : 8]), .out(gm3_13) );
assign mixCol_col[3][23:16] = gm2_13 ^ gm3_13 ^ shiftRow_col[3][31 : 24] ^ shiftRow_col[3][7 : 0] ; 

galiosMul2 inst_name53 (.in(shiftRow_col[3][15 : 8]), .out(gm2_23) );
galiosMul3 inst_name63 (.in(shiftRow_col[3][7 : 0]), .out(gm3_23) );
assign mixCol_col[3][15:8] = gm2_23 ^ gm3_23 ^ shiftRow_col[3][31 : 24] ^ shiftRow_col[3][23 : 16] ; 

galiosMul2 inst_name73 (.in(shiftRow_col[3][7 : 0]), .out(gm2_33) );
galiosMul3 inst_name83 (.in(shiftRow_col[3][31 : 24]), .out(gm3_33) );
assign mixCol_col[3][7:0] = gm2_33 ^ gm3_33 ^ shiftRow_col[3][23 : 16] ^ shiftRow_col[3][15 : 8] ; 


genvar i;
generate
for (i = 3 ; i>=0 ; i= i-1)
    begin 
    assign mixCol_o[32*i+31 :32*i] =mixCol_col[i] ;
    end
endgenerate


endmodule 


