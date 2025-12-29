`timescale 1ns / 1ps

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