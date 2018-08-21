function cf = polyfit(x,y,n)
A = ones(length(x),n+1)
for i=1:n
    A(:,i+1) = x(:).^i
end
cf = lsq(A,y(:))
endfunction
