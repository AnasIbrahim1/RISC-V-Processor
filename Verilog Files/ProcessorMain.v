/*******************************************************************
*
* Module: ProcessorMain.v
* Project: Processor
* Authors: Anas A. Ibrahim - anas2@aucegypt.edu, Ibrahim Gohar - 
abdelmaksou@aucegypt.edu

* Description: main processor circuit, where all the modules are combined
*
* Change history: 06/11/2022 - Added from Lab 6
                  06/11/2022 - Additional gates/muxes/modules were added to support all
                  instruction
                  13/11/2022 - Added Pipelining and Single Ported Single Memory
*
**********************************************************************/
`include "defines.v"

module ProcessorMain (
    input ssd_clk,
    input clk,
    input rst,
    input[1 : 0] led_sel,
    input[3 : 0] ssd_sel,
    output reg[15 : 0] leds,
    output reg[12 : 0] ssd
);

    wire clk_bar;
    assign clk_bar = ~clk;
    // ----------------------------- IF ------------------------------                

    wire[31 : 0] pc_in;
    wire[31 : 0] pc_out;
    NBitRegister nBitRegister(clk, rst, 1, pc_in, pc_out);
    
    wire cout0;
    wire[31 : 0] pc_4;
    Adder adder0(pc_out, 4, 0, pc_4, cout0);

    wire[31 : 0] inst;
    // --------------------------- IFID ------------------------------                
    wire[95 : 0] IFID_out;
    NBitRegister #(96) IFID(clk_bar, rst, 1, { pc_4, pc_out, inst }, IFID_out);
    wire[31 : 0] pc_4_IFID_out, pc_IFID_out, inst_IFID_out;
    assign pc_4_IFID_out    = IFID_out[`reg_IFID_pc_4   ];    
    assign pc_IFID_out      = IFID_out[`reg_IFID_pc     ];
    assign inst_IFID_out    = IFID_out[`reg_IFID_inst   ];
    // ----------------------------- ID ------------------------------                
    wire[31 : 0] imm;
    ImmGen immGen(inst_IFID_out, imm);        

    wire Branch, MemRead, MemWrite, ALUSrc, RegWrite;
    wire[1 : 0] MemtoReg, branch_cu;
    wire[2 : 0] ALUOp;
    ControlUnit controlUnit( inst_IFID_out[`IR_opcode], Branch, MemRead, 
    MemtoReg, ALUOp, MemWrite, ALUSrc, RegWrite, branch_cu);
    
    wire[31 : 0] read_data_1, read_data_2, new_write_data;
    RegFile regFile(clk_bar, rst, RegWrite, inst_IFID_out[`IR_rs1], 
    inst_IFID_out[`IR_rs2], inst[`IR_rd], new_write_data, read_data_1, 
    read_data_2);
    // --------------------------- IDEX ------------------------------                
    wire[185 : 0] IDEX_out;
    NBitRegister #(186) IDEX(clk, rst, 1, { pc_4_IFID_out, inst[`IR_shamt], 
    Branch, MemRead, MemWrite, ALUSrc, RegWrite, 
    MemtoReg, branch_cu, ALUOp, pc_IFID_out, read_data_1, read_data_2, imm, 
    inst[`IR_funct7bit], inst[`IR_funct3], inst[`IR_rd] }, IDEX_out);
    
    wire Branch_IDEX_out, MemRead_IDEX_out, MemWrite_IDEX_out, ALUSrc_IDEX_out, 
    RegWrite_IDEX_out;
    wire[1 : 0] MemtoReg_IDEX_out, branch_cu_IDEX_out;
    wire[2 : 0] ALUOp_IDEX_out;
    wire[31 : 0] pc_4_IDEX_out, pc_IDEX_out, read_data_1_IDEX_out, 
    read_data_2_IDEX_out, imm_IDEX_out;
    wire funct7bit;
    wire[2 : 0] funct3_IDEX_out;
    wire[4 : 0] inst_rd;
    wire[4 : 0] inst_shamt;
    
    assign pc_4_IDEX_out        = IDEX_out[`reg_IDEX_pc_4           ];
    assign Branch_IDEX_out      = IDEX_out[`reg_IDEX_Branch         ];
    assign MemRead_IDEX_out     = IDEX_out[`reg_IDEX_MemRead        ];
    assign MemWrite_IDEX_out    = IDEX_out[`reg_IDEX_MemWrite       ];
    assign ALUSrc_IDEX_out      = IDEX_out[`reg_IDEX_ALUSrc         ];
    assign RegWrite_IDEX_out    = IDEX_out[`reg_IDEX_RegWrite       ];
    assign MemtoReg_IDEX_out    = IDEX_out[`reg_IDEX_MemtoReg       ];
    assign branch_cu_IDEX_out   = IDEX_out[`reg_IDEX_branch_cu      ];
    assign ALUOp_IDEX_out       = IDEX_out[`reg_IDEX_ALUOp          ];    
    assign pc_IDEX_out          = IDEX_out[`reg_IDEX_pc             ];
    assign read_data_1_IDEX_out = IDEX_out[`reg_IDEX_read_data_1    ];
    assign read_data_2_IDEX_out = IDEX_out[`reg_IDEX_read_data_2    ];
    assign imm_IDEX_out         = IDEX_out[`reg_IDEX_imm            ];    
    assign funct7bit            = IDEX_out[`reg_IDEX_funct7bit      ];
    assign funct3_IDEX_out      = IDEX_out[`reg_IDEX_funct3         ];
    assign inst_rd              = IDEX_out[`reg_IDEX_inst_rd        ];
    assign inst_shamt           = IDEX_out[`reg_IDEX_inst_shamt     ];
    
    // ----------------------------- EX ------------------------------            
    wire cout3;
    wire[31 : 0] pc_imm;
    Adder adder1(pc_IDEX_out, imm_IDEX_out, 0, pc_imm, cout3);
        
    wire[31 : 0] alu_in_2;
    MUX mux_alu(read_data_2_IDEX_out, imm_IDEX_out, ALUSrc_IDEX_out, alu_in_2);    
    
    wire[3 : 0] ALUSel;
    ALUControl ALUControl0(ALUOp_IDEX_out, funct3, funct7bit, ALUSel);
    
    wire cf, zf, vf, sf;
    wire[31 : 0] alu_out;
    ALU ALU0(read_data_1_IDEX_out, alu_in_2, 
    (ALUSrc ? inst_shamt : alu_in_2[4 : 0]), alu_out, cf, zf, vf, sf, ALUSel);
    // -------------------------- EXMEM ------------------------------                
    wire Branch_EXMEM_out, MemRead_EXMEM_out, MemWrite_EXMEM_out;
    wire[2 : 0] funct3_EXMEM_out;
    wire cf_EXMEM_out, zf_EXMEM_out, vf_EXMEM_out, sf_EXMEM_out;
    wire[1 : 0] MemtoReg_EXMEM_out, branch_cu_EXMEM_out;
    wire[31 : 0] pc_EXMEM_out, alu_EXMEM_out, read_data_2_EXMEM_out, 
    pc_4_EXMEM_out, pc_imm_EXMEM_out;
    wire imm_bit_EXMEM_out;
    
    wire[174 : 0] EXMEM_out;
    NBitRegister #(175) EXMEM(clk_bar, rst, 1, { MemtoReg_IDEX_out,
    MemRead_IDEX_out, MemWrite_IDEX_out, imm_IDEX_out[0], pc_imm,
    Branch_IDEX_out, funct3_IDEX_out, cf, zf, vf, sf, branch_cu_IDEX_out,
    pc_IFID_out, alu_out, read_data_2_IDEX_out, pc_4_IDEX_out }, EXMEM_out);
    
    assign MemtoReg_EXMEM_out       = EXMEM_out[`reg_EXMEM_MemtoReg     ];
    assign MemWrite_EXMEM_out       = EXMEM_out[`reg_EXMEM_MemWrite     ];
    assign MemRead_EXMEM_out        = EXMEM_out[`reg_EXMEM_MemRead      ];
    assign imm_bit_EXMEM_out        = EXMEM_out[`reg_EXMEM_imm          ];    
    assign pc_imm_EXMEM_out         = EXMEM_out[`reg_EXMEM_pc_imm       ];
    assign Branch_EXMEM_out         = EXMEM_out[`reg_EXMEM_Branch       ];
    assign funct3_EXMEM_out         = EXMEM_out[`reg_EXMEM_funct3       ];
    assign cf_EXMEM_out             = EXMEM_out[`reg_EXMEM_cf           ];
    assign zf_EXMEM_out             = EXMEM_out[`reg_EXMEM_zf           ];
    assign vf_EXMEM_out             = EXMEM_out[`reg_EXMEM_vf           ];
    assign sf_EXMEM_out             = EXMEM_out[`reg_EXMEM_sf           ];
    assign branch_cu_EXMEM_out      = EXMEM_out[`reg_EXMEM_branch_cu    ];
    assign pc_EXMEM_out             = EXMEM_out[`reg_EXMEM_pc           ];
    assign alu_EXMEM_out            = EXMEM_out[`reg_EXMEM_alu          ];
    assign read_data_2_EXMEM_out    = EXMEM_out[`reg_EXMEM_read_data_2  ];
    assign pc_4_EXMEM_out           = EXMEM_out[`reg_EXMEM_pc_4         ]; 
    // ---------------------------- MEM ------------------------------            
    
    wire[1 : 0] branch_signal;
    BranchControlUnit branchControlUnit(Branch_EXMEM_out, funct3_EXMEM_out, 
    cf_EXMEM_out, zf_EXMEM_out, vf_EXMEM_out, sf_EXMEM_out, branch_signal);

    wire[1 : 0] PCSrc;
    MUX mux_branch_signal(branch_cu_EXMEM_out, branch_signal, Branch_EXMEM_out,
    PCSrc);
    
    wire[31 : 0] system;
    MUX mux4(0, pc_EXMEM_out, imm_bit_EXMEM_out, system);

    MUXFour mux_branch(pc_4_EXMEM_out, pc_imm_EXMEM_out, alu_EXMEM_out, system, 
    PCSrc, pc_in);        
        
    wire[31 : 0] mem_read_data;
    
    wire[8 : 0] mem_addr;
    MUX mem_mux(alu_EXMEM_out[8 : 0], pc_out[8 : 0], clk, mem_addr);
    
    SingleMem singleMem(clk, MemRead_EXMEM_out, MemWrite_EXMEM_out, 
    funct3_EXMEM_out, mem_addr, read_data_2_EXMEM_out, inst, mem_read_data);
    // -------------------------- MEMWB ------------------------------            
    wire[1 : 0] MemtoReg_MEMWB_out;
    wire[31 : 0] alu_MEMWB_out, mem_read_data_MEMWB_out, pc_4_MEMWB_out, 
    pc_imm_MEMWB_out;
    
    wire[129 : 0] MEMWB_out;
    NBitRegister #(130) MEMWB(clk, rst, 1, { MemtoReg_EXMEM_out,
    alu_EXMEM_out, mem_read_data, pc_4_EXMEM_out, pc_imm_EXMEM_out },
    MEMWB_out);
    
    assign MemtoReg_MEMWB_out       = MEMWB_out[`reg_MEMWB_MemtoReg     ];
    assign alu_MEMWB_out            = MEMWB_out[`reg_MEMWB_alu          ];
    assign mem_read_data_MEMWB_out  = MEMWB_out[`reg_MEMWB_mem_read_data];
    assign pc_4_MEMWB_out           = MEMWB_out[`reg_MEMWB_pc_4         ];
    assign pc_imm_MEMWB_out         = MEMWB_out[`reg_MEMWB_pc_imm       ];
    // ----------------------------- WB ------------------------------            
    MUXFour mux_final(alu_EXMEM_out, mem_read_data_MEMWB_out, pc_4_MEMWB_out, pc_imm_MEMWB_out, MemtoReg_MEMWB_out, new_write_data);
    
    // ---------------------------------------------------------------            
    
    always @(posedge ssd_clk) begin
        if (led_sel == 0) leds = inst[15 : 0];
        else if (led_sel == 1) leds = inst[31 : 16];
        else leds = {Branch, MemRead, MemtoReg, ALUOp, MemWrite, ALUSrc, RegWrite, ALUSel, zf, 1'b0};
        
        if (ssd_sel == 0) ssd = pc_out[12 : 0];
        else if (ssd_sel == 1) ssd = pc_4[12 : 0];
        else if (ssd_sel == 2) ssd = pc_imm[12 : 0];
        else if (ssd_sel == 3) ssd = pc_in[12 : 0];
        else if (ssd_sel == 4) ssd = read_data_1[12 : 0];
        else if (ssd_sel == 5) ssd = read_data_2[12 : 0];
        else if (ssd_sel == 6) ssd = new_write_data[12 : 0];
        else if (ssd_sel == 7) ssd = imm[12 : 0];
        else if (ssd_sel == 8) ssd = alu_in_2[12 : 0];
        else if (ssd_sel == 9) ssd = alu_out[12 : 0];
        else if (ssd_sel == 10) ssd = mem_read_data_MEMWB_out[12 : 0];
        else ssd = pc_out[12 : 0];
    end
    
endmodule
