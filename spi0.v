module spi0 (clk, reset, irq, address, byteenable, chipselect, writedata, readdata, write, read, tx, rx, clock, cs0, cs1, cs2, cs3);

    // Clock, reset, and interrupt
    input   clk, reset;
    output  irq;

    // Avalon MM interface (8 word aperature)
    input             read, write, chipselect;
    input [2:0]       address;
    input [3:0]       byteenable;
    input [31:0]      writedata;
    output reg [31:0] readdata;
    
    // spi interface
    output reg   		 clock, cs0, cs1, cs2, cs3, tx;
	 input				 rx;	
	 
	 // status reg
	 wire rx_FO;
	 wire rx_FF;
	 wire rx_FE;
	 wire tx_FO;
	 wire tx_FF;
	 wire tx_FE;
	 reg tx_clearOV;
	 reg rx_clearOV;
	 
	 //control reg
	 wire[1:0] CS_SELECT;
	 wire[3:0] CS_AUTO, CS_ENABLE;
	 wire[5:0] COUNT;
	 
	 wire[1:0] MODE0 = control[17:16];
	 wire[1:0] MODE1 = control[19:18];
	 wire[1:0] MODE2 = control[21:20];
	 wire[1:0] MODE3 = control[23:22];
	 
	 assign CS_AUTO = control[8:5];
	 assign CS_ENABLE = control[12:9];
	 assign CS_SELECT = control[14:13];
	 
	 //baudrate
	 reg enable;
	 
	 //FIFO
	 wire[31:0] fifo_readdata, fifo_writedata;
	 
    // internal    
    reg [31:0] data;
    reg [15:0] status;
	 reg [31:0] control;
    reg [31:0] brd;

    // register map
    // ofs  fn
    //   0  data (r/w)
    //   4  status (r/w1c)
    //   8  control (r/w)
    //  12  brd (r/w)

    // register numbers
    parameter DATA_REG             = 3'b000;
    parameter STATUS_REG           = 3'b001;
    parameter CONTROL_REG          = 3'b010;
    parameter BRD_REG       		  = 3'b011;
    
    // read register
    always @ (*)
    begin
        if (read && chipselect)
            case (address)
					DATA_REG:
						readdata = fifo_readdata;
               STATUS_REG:
						readdata = {10'b0, rx_FO, rx_FF, rx_FE, 
									 tx_FO, tx_FF, tx_FE};
               CONTROL_REG: 
						readdata = control;
               BRD_REG: 
                  readdata = brd;
            endcase
        else
            readdata = 32'b0;
    end        

    // write register
    always @ (posedge clk)
    begin
        if (reset)
        begin
            status <= 32'b0;
            control <= 32'b0;
            brd <= 32'b0;
        end
        else
        begin
				begin
                if (write && chipselect)
                begin
                    case (address)
                        STATUS_REG: 
                            status <= writedata;
                        CONTROL_REG: 
                            control <= writedata;
                        BRD_REG: 
                            brd <= writedata;
                    endcase
                end
                else
                    status <= 32'b0;
            end
        end
	 end
	 
	 //BRD
	 wire baudOut, clkOut;
	 baud_rate br(
		.clk(clk), 
		.reset(reset),
		.enable(enable),
		.brd(brd),
		.baudOut(baudOut),
		.clkDivide2(clkOut)
	 ); 
	
	 //FIFO
	 wire read_fifo;
	 wire write_fifo;
 	 
	 //fifo interface
	 assign read_fifo = read && chipselect && (address == DATA_REG);
	 assign write_fifo = write && chipselect && (address == DATA_REG);
	 assign fifo_writedata = writedata;
	 
	 //TX FIFO
	 wire [31:0] txData;
	 wire txReset;
	 assign txReset = reset || !enable;
	 wire fifo_tx_read;
	 FIFO tx_fifo(
		.clk(clk), 
		.reset(txreset), 
		.write(write_fifo), 
		.dataIn(fifo_writedata), 
		.read(fifo_tx_read), 
		.dataOut(txData), 			//txData
		.empty(tx_FE), 
		.full(tx_FF), 
		.ov(tx_FO), 
		.clearOV(tx_clearOV)
	 );
	 
	 //RX FIFO
	 wire [31:0] rxData;
	 wire rxWrite, rxReset;
	 wire [3:0] readPtr, writePtr;
	 assign rxReset = reset || !enable;
	 assign rxData = data;
	 FIFO rx_fifo(
		.clk(clk), 
		.reset(rxreset), 
		.write(rxWrite), 
		.dataIn(rxData), 				//rxData
		.read(read_fifo), 
		.dataOut(fifo_readdata), 
		.empty(rx_FE), 
		.full(rx_FF), 
		.ov(rx_FO), 
		.clearOV(rx_clearOV),
		.readPtr(readPtr), 
		.writePtr(writePtr)
	 );
	 	 
	 //Serializer
	 parameter IDLE 		= 3'b100;
	 parameter CS_ASSERT = 3'b101;
	 parameter TX_BITS 	= 3'b110;
	 
	 reg lastBrd;
	 wire load, dec;
	 reg[2:0] state, nextState;
	 always @(posedge clk) 
		if(reset) 	state <= IDLE;
			else
			begin
				state <= nextState;
				lastBrd <= clock;
			end
	 always @(state)
		case(state)
			IDLE: 
			begin
				if(!tx_FE && CS_AUTO)
					nextState <= CS_ASSERT;
				if(!tx_FE && !CS_AUTO)
					nextState <= TX_BITS;
				if(tx_FE)
					nextState <= IDLE;
			end
			CS_ASSERT:
			begin
				nextState <= TX_BITS;
			end
			TX_BITS:
			begin
				clock <= clkOut ^ SPO ^ SPH;
				if(COUNT == 1'b0)
					nextState <= IDLE;
				else
					nextState <= TX_BITS;
			end
		endcase

	always@(clock)		
	begin			
		if(state == TX_BITS && COUNT > 0 && lastBrd != clock)
		begin
			tx <= txData[COUNT-1];
			data[COUNT-1] <= rx;
		end
		else
			tx <= 1'b0;			
	end
		
		assign load = (state == IDLE);
		assign dec = (state == TX_BITS);
		
	counter counter(.clk(clk), .reset(reset), .value(control[4:0]), .load(load), .dec(dec), .count(COUNT));

	always@(*)
	begin 
		if(!(CS_AUTO[CS_SELECT]) && CS_ENABLE[CS_SELECT]) begin
			if	(CS_SELECT == 2'b00)			cs0 <= 1'b1;
			else if(CS_SELECT == 2'b01)	cs1 <= 1'b1;
			else if(CS_SELECT == 2'b10)	cs2 <= 1'b1;
			else if(CS_SELECT == 2'b11)	cs3 <= 1'b1;
		end
		else if (CS_AUTO[CS_SELECT] && state != IDLE) begin
			if	(CS_SELECT == 2'b00)			cs0 <= 1'b1;
			else if(CS_SELECT == 2'b01)	cs1 <= 1'b1;
			else if(CS_SELECT == 2'b10)	cs2 <= 1'b1;
			else if(CS_SELECT == 2'b11)	cs3 <= 1'b1;
		end
	end
	
	reg SPO, SPH;
	always @(*)
	begin
		case(CS_SELECT)
			2'b00: begin SPO = MODE0[1]; SPH = MODE0[0]; end
			2'b01: begin SPO = MODE1[1]; SPH = MODE1[0]; end
			2'b10: begin SPO = MODE2[1]; SPH = MODE2[0]; end
			2'b11: begin SPO = MODE3[1]; SPH = MODE3[0]; end
		endcase
	end
	
	
			
endmodule

module FIFO (clk, reset, write, dataIn, read, dataOut, empty, full, ov, clearOV, readPtr, writePtr);
	input clk, reset, write, read, clearOV;
	input [31:0] dataIn;
	output reg [31:0] dataOut; 
	output full, empty;
	output reg ov;	 	
	output reg [3:0] readPtr, writePtr; 
	
	reg [3:0] PtrDiff; 
	reg [31:0] Stack [15:0];
	reg lastReadPtr, lastWritePtr;
	
	assign empty = (readPtr == writePtr); 
	assign full = (readPtr == PtrDiff); 
	
	always @ (posedge clk or posedge reset or posedge clearOV) begin 
		if (reset) begin 
			dataOut <= 1'b0; 
			readPtr <= 1'b0; 
			writePtr <= 1'b0; 
			PtrDiff <= 1'b1; 
			ov <= 1'b0;
			lastReadPtr <= 1'b0;
		end
		else if (clearOV) begin
			ov <= 1'b0;
		end
		else begin 
			lastReadPtr <= read;
			if (read && !lastReadPtr) begin
				if (empty) begin
					dataOut <= 1'b0; 
				end
				else begin
					dataOut <= Stack[readPtr]; 
					readPtr <= readPtr + 4'b1; 
				end
			end
			lastWritePtr <= write;
			if (write && !lastWritePtr) begin
				if (!full) begin 
					Stack[writePtr] <= dataIn; 
					writePtr <= writePtr + 4'b1; 
					PtrDiff <= PtrDiff + 4'b1; 
				end
				else begin
					ov <= 1; 
				end
			end
		end
	end
endmodule

module baud_rate(clk, reset, enable, brd, baudOut, clkDivide2);
	input clk, reset, enable;
	input [31:0] brd;
	output reg baudOut, clkDivide2;
	
	reg [31:0] count;
	reg [31:0] match;
		always @ (posedge clk) 
		begin
			if (reset || !enable) 
			begin
				baudOut <= 1'b0;
				clkDivide2 <= 1'b0;
				count <= 32'b0;
				match <= brd;
			end
			else begin
				clkDivide2 <= ~clkDivide2;
				count <= count + 32'b10000000;
				if (count[31:7] == match[31:7])	
				begin
					match <= match + brd;
					baudOut <= ~baudOut;
				end 
			end
		end
endmodule

module counter(clk, reset, value, load, dec, count);
	input clk, reset, load, dec;
	input [4:0] value;
	output reg [5:0] count;
		always @(posedge clk)
			if(reset)
				count <= 0;
			else
				if(load)
					count <= value + 1'b1;
				else if(dec)
					count <= count - 1'b1;
endmodule


