`timescale 1ns / 1ps

module APB_SLAVE(

input pclk,
input presetn,
input psel,
input penable,
input pwrite,
input [31:0] pwdata,
input [31:0] paddr,
input s_wait,

output reg pready,
output reg [31:0] prdata,
output reg pslverr,

input [2:0] pprot,
input [3:0] pstrb,

input parity

    );
    
reg [31:0] mem [15:0];
reg [31:0] mem_sec [15:0];

localparam idle = 0,write = 1,read = 2;
reg [2:0] state;

reg slave_parity;
wire addr_err;
wire parity_err;
wire err;

assign addr_err = (paddr > 32'd15) ? 1'b1 : 1'b0;
assign parity_err = (parity == slave_parity) ? 1'b0 : 1'b1;

assign err = (addr_err | parity_err);



always @(posedge pclk or negedge presetn) 
begin 

    if(!presetn) begin 
        pready <= 1'b0;
        prdata <= 32'h0;
        pslverr <= 1'b0;
        slave_parity <= 1'b0;
        state <= idle;
    end
    
    else begin 
        
        case(state)
            idle:
            begin 
                pready <= 1'b0;
                prdata <= 32'h0;
                pslverr <= 1'b0;
                if(psel && !penable)
                state <= pwrite ? write : read;
            end
            
            write:
            begin 
                if(psel && penable) begin
                 slave_parity <= ^pwdata;
                    if(s_wait) begin 
                        state <= write;
                    end
                    
                    else begin
                            if(!addr_err) begin 
                                if(pprot == 3'b010)
                                begin 
                                    if (pstrb[0]) mem[paddr][7:0]   <= pwdata[7:0];
                                    if (pstrb[1]) mem[paddr][15:8]  <= pwdata[15:8];
                                    if (pstrb[2]) mem[paddr][23:16] <= pwdata[23:16];
                                    if (pstrb[3]) mem[paddr][31:24] <= pwdata[31:24];

                                end
                                else if(pprot == 3'b000)
                                begin 
                                    if (pstrb[0]) mem_sec[paddr][7:0]   <= pwdata[7:0];
                                    if (pstrb[1]) mem_sec[paddr][15:8]  <= pwdata[15:8];
                                    if (pstrb[2]) mem_sec[paddr][23:16] <= pwdata[23:16];
                                    if (pstrb[3]) mem_sec[paddr][31:24] <= pwdata[31:24];
                                end
                                pready <= 1'b1;
                                state <= idle;
                                pslverr <= err;
                            end
                            else begin 
                                state <= idle;
                                pready <= 1'b1;
                                pslverr <= err;
                            end
                         end
                end
            end
           
            read:
            begin 
                if(psel && penable) begin 
                        if(s_wait) begin 
                            state <= read;
                        end
                        
                        else begin 
                            if(!addr_err) begin 
                            
                                if(pprot == 3'b010)
                                begin 
                                    prdata <= mem[paddr];
                                end 
                                else if(pprot == 3'b000)
                                begin 
                                    prdata <= mem_sec[paddr];
                                end
                                    pready <= 1'b1;
                                    
                                state <= idle;
                                pslverr <= err;
                            end
                            
                            else begin 
                                state <= idle;
                                pready <= 1'b1;
                                pslverr <= err;
                            end
                        end
                    end
            end
            default : state <= idle;
        endcase
    end
end


    

endmodule
