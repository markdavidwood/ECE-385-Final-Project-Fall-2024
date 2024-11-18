// 
module score_board(
    input logic reset,
    // max score is 9999, and we need 14 bits to represent that                   
    input logic [13:0] score,
    // 5-bit output signals for each digit of the score
    output logic [3:0] thousands,         
    output logic [3:0] hundreds,           
    output logic [3:0] tens,               
    output logic [3:0] ones             
);
    // Constants for representing the values 10, 100, and 1000
    logic [3:0] ten = 10;                       
    logic [6:0] hundred = 100;                 
    logic [9:0] thousand = 1000;                

    // using always_comb because the score board should be updated based on specific conditions, not every clock cycle
    always_comb begin      
        // initialize all digits to 0                    
        thousands = 4'b0;                  
        hundreds = 4'b0;                  
        tens = 4'b0;                       
        ones = 4'b0;                    

        if (reset) 
        begin
            // if reset, set all digits to 0                       
            thousands = 4'b0;              
            hundreds = 4'b0;               
            tens = 4'b0;                  
            ones = 4'b0;                
        end 
        else 
        begin    
            // Calculate the thousand's place digit (score divided by 1000, then modulo 10)
            thousands = (score / thousand) % ten;         
            // Calculate the hundred's place digit (score divided by 100, then modulo 10)
            hundreds = (score / hundred) % ten;   
            // Calculate the ten's place digit (score divided by 10, then modulo 10)        
            tens = (score / ten) % ten;             
            // Calculate the single's place digit (score modulo 10)
            ones = score % ten; 
        end
    end
endmodule