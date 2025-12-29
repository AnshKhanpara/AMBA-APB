`timescale 1ns / 1ps



module APB_TOP(
input pclk,
input presetn,
input [31:0] datain,
input [31:0] addrin,
input wr,
input newd,
input s_wait,

output [31:0]dataout,
output err,

input [2:0]pprot_in,
input [3:0]pstrb_in
    );

wire pwrite,psel,penable,pready,pslverr;
wire [2:0]pprot;
wire [3:0]pstrb;
wire parity;
wire [31:0] pwdata,paddr,prdata; 

APB_MASTER u_master (
        .pclk     (pclk),
        .presetn  (presetn),
        .wr       (wr),
        .newd     (newd),
        .datain   (datain),
        .addrin   (addrin),
        .prot     (pprot_in),   
        .strb     (pstrb_in),  

        .psel     (psel),
        .penable  (penable),
        .pwrite   (pwrite),
        .paddr    (paddr),
        .pwdata   (pwdata),

        .pready   (pready),
        .prdata   (prdata),
        .pslverr  (pslverr),
        .err      (err),
        .dataout  (dataout),

        .pprot    (pprot),
        .pstrb    (pstrb),

        .parity   (parity)
    );

    // SLAVE
APB_SLAVE u_slave (
        .pclk     (pclk),
        .presetn  (presetn),
        .psel     (psel),
        .penable  (penable),
        .pwrite   (pwrite),
        .pwdata   (pwdata),
        .paddr    (paddr),
        .s_wait   (s_wait),

        .pready   (pready),
        .prdata   (prdata),
        .pslverr  (pslverr),

        .pprot    (pprot),
        .pstrb    (pstrb),

        .parity   (parity)
    );


endmodule
/////////MASTER/////////////
module APB_MASTER(

input pclk, // syncronous clock 
input presetn, // reset 
input wr, // write or read signal used by user
input newd, // signal used by user to demand new data
input [31:0] datain, // data given by user
input [31:0] addrin, // addr given by user
input [2:0] prot, // protection given by user
input [3:0] strb, // maesking gived by user

output reg psel,// selection of slave
output reg penable,// enable signal shows that second cycle is initiated
output reg pwrite,// write signal for slave
output reg [31:0] paddr,
output reg [31:0] pwdata,

input  pready, // output of slave , shows that slave is ready for next cycle
input [31:0] prdata, // read data
input pslverr,
output reg err,
output reg [31:0]dataout, // data out 

output reg [2:0] pprot, // protection signal
output reg [3:0] pstrb, // masking signal

//input wake_up , // slave gives wake up signal to master
output wire parity  // to check the parity
);
assign parity = ^pwdata;
parameter [1:0] idle = 0, setup = 1, access = 2;

reg [1:0] state , nstate;
reg req_pending;
//////////// RESET LOGIC /////////////////
always @(posedge pclk or negedge presetn)
begin 
    if(!presetn) begin // this is a active low reset
        state <= idle;
        
    end
    else begin
        state <= nstate;
      
    end
end 
///////////////pending request////////////////////
/* 
so now we are adding a logic where we counter a problem that if newd is of single bit then?
then what if we are in state access and new request comes and pready is still low that means request is lost
so for that we will use req_pending 
*/

always@(posedge pclk or negedge presetn)
begin 
    if(!presetn)begin 
        req_pending <= 1'b0;
    end
    
    else if(state == setup)
        req_pending <= 1'b0;
    
    else if(newd) begin 
        req_pending <= 1'b1;
    end
    
    
end
////////////////// STATE LOGIC ///////////////////
always@(*) begin 
    nstate = state;
    case(state)
        idle: 
        begin 
            if(req_pending)
                nstate = setup;
            else 
                nstate = idle;
        end
        
        setup:
            nstate = access;
            
        access:
        begin 
            nstate = (pready) ? (req_pending? setup:idle) : (access);
        end
        default : nstate = idle;
    endcase
end
//////////////PSEL////////////////
always @(posedge pclk or negedge presetn)
begin 
    if(!presetn)
    begin 
        psel <= 1'b0;
        penable <= 1'b0;
    end
    else 
    begin 
    case(state)
        idle:
        begin 
            psel <= 1'b0;
            penable <= 1'b0;
        end
        
        setup:
        begin 
            psel <= 1'b1;
            penable <= 1'b0;
         end   
        access: begin 
            psel <= 1'b1;
            penable <= 1'b1;
          end 
       default begin 
            psel <= 1'b0;
            penable <= 1'b0;
       end
    endcase
    end
end


/////////////OUTPUT LOGIC/////////////////
always @(posedge pclk or negedge presetn)
begin 
    if(!presetn) begin 
        pwrite <= 1'b0;
        paddr <= 32'h0;
        pwdata <= 32'h0;
        dataout <= 32'h0;
        pprot <= 0;
        pstrb <= 0;
        err <= 1'b0;
    end
    
    else begin 
        
            case(state)
                idle:
                begin
                    pwrite <= 1'b0;
                    paddr <= 32'h0;
                    pwdata <= 32'h0;
                    //dataout <= 32'h0;
                    pprot <= prot;
                    pstrb <= strb;
                end
                
                setup:
                begin 
                    pwrite <= wr;
                    paddr <= addrin;
                    pprot <= prot;
                    pstrb <= strb;
                    if (wr) begin 
                        pwdata <= datain;
                    end
                    
                end
                
                access:
                begin 
                    if(pready)begin
                        err <= pslverr;
                        if(!pwrite) begin
                            dataout <= prdata;    
                        end
                    end
                end
            endcase
        end
    
end
endmodule

///////////SLAVE//////////////
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