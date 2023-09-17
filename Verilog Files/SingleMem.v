/*******************************************************************
*
* Module: SingleMem.v
* Project: Processor
* Authors: Anas A. Ibrahim - anas2@aucegypt.edu, Ibrahim Gohar - 
abdelmaksou@aucegypt.edu

* Description: single memory
*
* Change history: 13/11/2022 - Coded down
**********************************************************************/

module SingleMem(
    input is_inst,
    input MemRead, 
    input MemWrite,
    input [2 : 0] funct3,
    input [8  : 0] addr, 
    input [31 : 0] in, 
    output reg[31 : 0] out,
    output reg[31 : 0] mem_out
);

    reg[7 : 0] mem[511 : 0];
    wire[8 : 0] new_addr;
    assign new_addr = { addr[7 : 0], is_inst };
    // data are even and instructions are odd
     always @(*) begin
        if (is_inst) begin
            out = {mem[new_addr + 6], mem[new_addr + 4], mem[new_addr + 2], mem[new_addr + 0]};
        end else begin
            if (MemWrite) begin 
                if (funct3 == `LS_FUNCT3_B) 
                    mem[new_addr] = in[7 : 0];
                else if (funct3 == `LS_FUNCT3_H) begin
                    mem[new_addr] = in[7 : 0];
                    mem[new_addr + 2] = in[15 : 8];                
                end else begin
                    mem[new_addr] = in[7 : 0];
                    mem[new_addr + 2] = in[15 : 8];                
                    mem[new_addr + 4] = in[23 : 16];
                    mem[new_addr + 6] = in[31 : 24];                
                end
            end 
            if (MemRead) begin
                if (funct3 == `LS_FUNCT3_B) 
                    out <= { { 24 { mem[new_addr][7] } }, mem[new_addr] };
                else if (funct3 == `LS_FUNCT3_H) 
                    out <= { { 16 { mem[new_addr + 2][7] } }, mem[new_addr + 2], mem[new_addr] };
                else if (funct3 == `LS_FUNCT3_BU) 
                    out <= { 24'b0 , mem[new_addr] };
                else if (funct3 == `LS_FUNCT3_HU) 
                    out <= { 16'b0 , mem[new_addr + 2], mem[new_addr] };
                else 
                    out <= { mem[new_addr + 6], mem[new_addr + 4], mem[new_addr + 2], mem[new_addr] };
            end
        end
        mem_out = out;
    end
    
    
    initial begin
    // memory data
        mem[0] = 8'd3;
        mem[2] = 8'd1;
        mem[4] = 8'd25;
        mem[6] = 8'd3;
        mem[8] = 8'd1;
        mem[10] = 8'd25;
        mem[12] = 8'd3;
        mem[14] = 8'd1;
        mem[16] = 8'd25;
        mem[18] = 8'd3;
        mem[20] = 8'd1;
        mem[22] = 8'd25;
        // inst data
        {mem[7], mem[5], mem[3], mem[1]} = 32'h01100093; //addi x1, x0, 17
        {mem[15], mem[13], mem[11], mem[9]} = 32'h01100093; //addi x1, x0, 17
        {mem[23], mem[21], mem[19], mem[17]} = 32'h01100093; //addi x1, x0, 17
        {mem[31], mem[29], mem[27], mem[25]} = 32'h01100093; //addi x1, x0, 17
    end    
endmodule
