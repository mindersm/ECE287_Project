// Has 4-bit, user-controlled input D
// Updates Q to current D on CLK if en = 1
module register(rst, CLK, D, Q, en);
	
	input rst; 
	input CLK; 
	input en;  
	input [15:0] D; 
	output [15:0] Q;
	reg [15:0] Q;
	
	always @(posedge CLK or negedge rst)
		if (rst == 1'b0)
			Q <= 16'd0;
		else
			begin
				if (en)
					Q <= D;
				else	
					Q <= Q;
			end
endmodule


module ALU(rst, CLK, src1, src2, dst, operation);
	input CLK, rst;
	input [2:0] operation;
	input [15:0] src1, src2;
	output [15:0] dst;
	reg [15:0] dst;
	reg one;
	
	always@(posedge CLK or negedge rst)
	begin
		if(rst == 1'b0)
		begin
			one <= 1'b0;
		end
		else
		if(one == 1'b0)
		begin
			case (operation)
			3'b000: // bitwise AND
				begin
				dst <= src1 & src2;
				one <= 1'b1;
				end
			3'b001: // bitwise OR
				begin
				dst <= src2 | src2;
				one <= 1'b1;
				end
			3'b010: // Add
				begin
				dst <= src1 + src2;
				one <= 1'b1;
				end
			3'b110: // Subtract
				begin
				dst <= src1 - src2;
				one <= 1'b1;
				end
			3'b011: // Set dst to 1;
				begin
				dst <= 16'd1;
				one <= 1'b1;
				end
			default: // Set dst to 1;
				begin
				dst <= 16'd1;
				one <= 1'b1;
				end
			endcase
		end
		else
			one <= 1'b0;
	end
endmodule


module Control(rst, CLK, instruction, out, person, LEDG);
	// inputs: 
	// 50 MHz Clock 
	// rst = SW17
	// instruction = [15:0]SW 
	input CLK, rst;
	input [1:0]person; // signal input from person (SW16) to determine if ALU will ultimately operate. Eventually drop this
	input [15:0] instruction;
	// output: out = [15:0]LEDR
	output [15:0] out;
	output [3:0] LEDG;
	// regs
	reg [2:0] S, NS;
	reg [3:0] LEDG;
	reg RegDst, RegWrite, ALUSrc;
	reg [1:0] ALUOp;
	reg [2:0] operation;	
	// regs to determine src1,2 and dst and to be passed to wires to pass to ALU module
	reg [15:0] src1_reg, src2_reg, inA_reg, inB_reg, inC_reg, inZ_reg;
	reg writeA_reg, writeB_reg, writeC_reg;
	// regs to assign control signals
	reg [5:0] OpCode_reg;
	reg [1:0] rs_reg, rt_reg, rd_reg;
	reg [3:0] funct_reg;
	reg [7:0] address_reg;
	// wires (control signals obtained from instruction)	
	wire [5:0] OpCode;
	wire [1:0] rs, rt, rd;
	wire [3:0] funct;
	wire [7:0] address;
   // wires for register inputs/outputs
	wire [15:0] zero, outA, outB, outC;
	wire [15:0] inA, inB, inC;
	wire writeA, writeB, writeC;
	// wires for src1,2 and dst
	wire [15:0] src1, src2, dst;
	
	// assign breakdown of instruction
	assign OpCode = OpCode_reg;
	assign rs = rs_reg;
	assign rt = rt_reg;
	assign rd = rd_reg;
	assign funct = funct_reg;
	assign address = address_reg;
	
	parameter IF = 2'b00;
	parameter ID = 2'b01;
	parameter EX = 2'b10;
	parameter DANGER = 2'b11;
	
	always@(*)
	begin
		case (S)
			IF:
			begin
			if (person == 2'b01)
				begin
				NS = ID;
				end
			else
				begin
				NS = IF;
				end
			end
			ID:
			begin
			if (person == 2'b10)
				begin
				NS = EX;
				end
			else
				begin
				NS = ID;
				end
			end
			EX:
			begin
			if (person == 2'b00)
				begin
				NS = IF;
				end
			else
				begin
				NS = EX;
				end
			end
			DANGER:
			begin
				NS = DANGER;
			end
		endcase
	end
	
	always@(posedge CLK or negedge rst)
	begin
		if(rst == 1'b0)
			S <= IF;
		else
			S <= NS;
	end
	
	always@(posedge CLK or negedge rst)
	begin
		if (rst == 1'b0)
		begin
			inA_reg <= 16'd0;
			inB_reg <= 16'd0;
			inC_reg <= 16'd0;
			inZ_reg <= 16'd0;
		end
		else
		case (S)
			IF:
			begin
				LEDG[3:0] <= 4'b0001;
				OpCode_reg <= instruction[15:10];
				rs_reg <= instruction[9:8];
				rt_reg <= instruction[7:6];
				rd_reg <= instruction[5:4];
				funct_reg <= instruction[3:0];
				address_reg <= instruction[7:0];				
			end
			ID:
			begin
				LEDG[3:0] <= 4'b0010;
				case (OpCode)
				6'd0: // R-Type Instruction
					begin
					RegDst <= 1'b1;
					ALUSrc <= 1'b0;
					RegWrite <= 1'b1;
					ALUOp <= 2'b10;
					end
				6'd35: // Load Instruction
					begin
					RegDst <= 1'b0;
					ALUSrc <= 1'b1;
					RegWrite <= 1'b1;				
					ALUOp <= 2'b00;
					end
				6'd43: // Store Instruction
					begin
					RegDst <= 1'b0;
					ALUSrc <= 1'b1;
					RegWrite <= 1'b0;				
					ALUOp <= 2'b00;
					end
				6'd4: // Branch Instruction
					begin
					RegDst <= 1'b0;
					ALUSrc <= 1'b0;
					RegWrite <= 1'b0;				
					ALUOp <= 2'b01;
					end
				6'd2: // Jump Instruction
					begin
					RegDst <= 1'b0;
					ALUSrc <= 1'b0;
					RegWrite <= 1'b0;				
					ALUOp <= 2'b00;
					end
				default: //doesn't matter right now cus I be's the Memory and PC
					begin
					RegDst <= 1'b0;
					ALUSrc <= 1'b0;
					RegWrite <= 1'b0;				
					ALUOp <= 2'b00;
					end
				endcase
				case (ALUOp)
					2'b00:
						begin
						operation <= 3'b010; // Add
						end
					2'b01:
						begin
						operation <= 3'b110; // Subtract
						end
					2'b10:
						begin
							case(funct)
								4'b0000:
									begin
									operation <= 3'b010; // Add
									end
								4'b0010:
									begin
									operation <= 3'b110; // Subtract
									end
								4'b0100:
									begin
									operation <= 3'b000; // AND
									end
								4'b0101:
									begin
									operation <= 3'b001; // OR
									end
								4'b1010:
									begin
									operation <= 3'b111; // Set on <
									end
								default:
									begin
									operation <= 3'b011; // Add (anything better?) will add 1 to dst.
									end
							endcase
						end
				endcase
			end
			EX:
			begin
				LEDG[3:0] <= 4'b0100;		
				// Determine register that to read for src1
				case (rs)
					2'b00:
						begin
						src1_reg <= zero;
						end
					2'b01:
						begin
						src1_reg <= outA;
						end
					2'b10:
						begin
						src1_reg <= outB;
						end
					2'b11:
						begin
						src1_reg <= outC;
						end
				endcase
				// Determine register to read for src2
				case (rt)
					2'b00:
						begin
						src2_reg <= zero;
						end
					2'b01:
						begin
						src2_reg <= outA;
						end
					2'b10:
						begin
						src2_reg <= outB;
						end
					2'b11:
						begin
						src2_reg <= outC;
						end
				endcase
				// Determine register to write back to (dst)
				case (rd)
					2'b00:
						begin
						inZ_reg <= 16'd0;
						writeA_reg <= 1'b0;
						writeB_reg <= 1'b0;
						writeC_reg <= 1'b0;
						end
					2'b01:
						begin
						inA_reg <= dst;
						writeA_reg <= RegWrite;
						writeB_reg <= 1'b0;
						writeC_reg <= 1'b0;
						end
					2'b10:
						begin
						inB_reg <= dst;
						writeA_reg <= 1'b0;
						writeB_reg <= RegWrite;
						writeC_reg <= 1'b0;
						end
					2'b11:
						begin
						inC_reg <= dst;
						writeA_reg <= 1'b0;
						writeB_reg <= 1'b0;
						writeC_reg <= RegWrite;
						end
				endcase
			end
			DANGER:
			begin
				LEDG[3:0] <= 4'b1000;
			end
		endcase
	end
	
	assign src1 = src1_reg;
	assign src2 = src2_reg;
	assign inA = inA_reg;
	assign inB = inB_reg;
	assign inC = inC_reg;
	assign writeA = writeA_reg;
	assign writeB = writeB_reg;
	assign writeC = writeC_reg;
	
	register inst_zero(rst, CLK, 16'd0, zero, 1'b1);  // instantiates the zero-dedicated register
	register inst_A(rst, CLK, inA, outA, writeA); // instantiates register A 
	register inst_B(rst, CLK, inB, outB, writeB); // instantiates register B 
	register inst_C(rst, CLK, inC, outC, writeC); // instantiates register C
	
	ALU inst_ALU(rst, CLK, src1, src2, dst, operation);

	// Assign final output
	assign out = outC;
	
endmodule
	
	
