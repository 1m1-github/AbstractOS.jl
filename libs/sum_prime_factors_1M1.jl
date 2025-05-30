@api function sum_prime_factors(n::Int)
    n <= 1 && return 0
    
    factors_sum = 0
    temp_n = abs(n)
    
    # Check for factor 2
    if temp_n % 2 == 0
        factors_sum += 2
        while temp_n % 2 == 0
            temp_n ÷= 2
        end
    end
    
    # Check odd factors from 3 onwards
    i = 3
    while i * i <= temp_n
        if temp_n % i == 0
            factors_sum += i
            while temp_n % i == 0
                temp_n ÷= i
            end
        end
        i += 2
    end
    
    # If temp_n is still greater than 1, it's a prime factor
    if temp_n > 1
        factors_sum += temp_n
    end
    
    return factors_sum
end
