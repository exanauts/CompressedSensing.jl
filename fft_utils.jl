using LinearAlgebra
using FFTW
using Random, Distributions

# compute M_{\perp}^{\top}z

# @param z_zero The zero-imputed signal, i.e. replacing all the missing values in the signal with 0.
# e.g. The signal is [2;3;missing;4], then z_zero = [2;3;0;4].
# @param dim The dimension of the problem (dim = 1, 2, 3)
# @param size The size of each dimension of the problem
#(we only consider the cases when the sizes are even for all the dimenstions)
#(size is a tuple, e.g. size = (10, 20, 30))

# @details This function computes M_{\perp}^{\top}z.

# @return M_{\perp}^{\top}z A vector with length equal to the product of size
# @example
# >widetildez = [2;3;missing;4];
# >z_zero  = [2;3;0;4];
# >dim = 1;
# >size1 = 4;
# >M_perptz = M_perp_tz(z_zero, dim, size1);

function M_perp_tz_wei(dim, size, z_zero)
    N = prod(size)
    temp = fft(z_zero) ./ sqrt(N)
    beta = DFT_to_beta(dim, size, temp)
    return beta
end

function M_perp_beta_wei(dim, size, beta, idx_missing)
    N = prod(size);
    v = beta_to_DFT(dim, size, beta)
    temp = real.(ifft(v)) .* sqrt(N)
    temp[idx_missing] .= 0
    return temp
end
function M_perpt_M_perp_vec_wei(dim, size, vec, idx_missing)
    temp = M_perp_beta_wei(dim, size, vec, idx_missing)
    temp = M_perp_tz_wei(dim, size, temp)
    return temp
end

# mapping between DFT and real vector beta

# mapping DFT to beta
# @param dim The dimension of the problem (dim = 1, 2, 3)
# @param size The size of each dimension of the problem
#(we only consider the cases when the sizes are even for all the dimenstions)
#(size is a tuple, e.g. size = (10, 20, 30))
# @param v DFT

# @details This fucnction maps DFT to beta

# @return A 1-dimensional real vector beta whose length is the product of size
# @example
# >dim = 2;
# >size1 = (6, 8);
# >x = randn(6, 8);
# >v = fft(x)/sqrt(prod(size1));
# >beta = DFT_to_beta(dim, size1, v);

function DFT_to_beta(dim, size, v)
    if (dim == 1)
        return DFT_to_beta_1d(v, size)
    elseif (dim == 2)
        return DFT_to_beta_2d(v, size)
    else
        return DFT_to_beta_3d(v, size)
    end
end

# dim = 1
function DFT_to_beta_1d_wei(v, size)
    N = size[1]
    M = N ÷ 2
    beta = [real(v[1]);
            real(v[M+1]);
            sqrt(2) .* real.(v[2:M]);
            sqrt(2) .* imag.(v[2:M])]
    return beta
end

function DFT_to_beta_1d!(beta, v, size)
    N = size[1]
    M = N ÷ 2
    beta[1] = real(v[1])
    beta[2] = real(v[M+1])
    for i in 2:M
        beta[i+1] = sqrt(2) * real(v[i])
        beta[M+i] = sqrt(2) * imag(v[i])
    end
    return beta
end

function DFT_to_beta_1d(v, size)
    N = size[1]
    beta = Vector{Float64}(undef, N)
    DFT_to_beta_1d!(beta, v, size)
end

# dim = 2
function DFT_to_beta_2d(v, size)
    N1 = size[1]
    N2 = size[2]
    M1 = N1 ÷ 2
    M2 = N2 ÷ 2
    beta = [real(v[1, 1]);
            real(v[1, M2+1]);
            real(v[M1+1, 1]);
            real(v[M1+1, M2+1]);
            sqrt(2) .* real.(v[1, 2:M2]);
            sqrt(2) .* imag.(v[1, 2:M2]);
            sqrt(2) .* real.(v[M1+1, 2:M2]);
            sqrt(2) .* imag.(v[M1+1, 2:M2]);
            sqrt(2) .* real.(v[2:M1, 1]);
            sqrt(2) .* imag.(v[2:M1, 1]);
            sqrt(2) .* real.(v[2:M1, M2+1]);
            sqrt(2) .* imag.(v[2:M1, M2+1]);
            sqrt(2) .* reshape(real.(v[2:M1, 2:M2]), (M1-1) * (M2-1));
            sqrt(2) .* reshape(imag.(v[2:M1, 2:M2]), (M1-1) * (M2-1));
            sqrt(2) .* reshape(real.(v[2:M1, M2+2:N2]), (M1-1) * (M2-1));
            sqrt(2) .* reshape(imag.(v[2:M1, M2+2:N2]), (M1-1) * (M2-1))]
    return beta
end

#
# function DFT_to_beta_2d(v, size)
#     N1 = size[1]
#     N2 = size[2]
#     beta = Vector{Float64}(undef, N1 * N2)
#     DFT_to_beta_2d!(beta, v, size)
# end

# dim = 3
function DFT_to_beta_3d(v, size)
    N1 = size[1]
    N2 = size[2]
    N3 = size[3]
    M1 = N1 ÷ 2
    M2 = N2 ÷ 2
    M3 = N3 ÷ 2
    beta = [real.(v[1,1,1]); real.(v[1,1,M3+1]); real.(v[1,M2+1,1]); real.(v[1,M2+1,M3+1]);
            real.(v[M1+1,1,1]); real.(v[M1+1,1,M3+1]); real.(v[M1+1,M2+1,1]); real.(v[M1+1,M2+1,M3+1]);
            sqrt(2).*(real.(v[1, 1, 2:M3]));
            sqrt(2).*(imag.(v[1, 1, 2:M3]));
            sqrt(2).*(real.(v[1, M2+1, 2:M3]));
            sqrt(2).*(imag.(v[1, M2+1, 2:M3]));
            sqrt(2).*(real.(v[M1+1, 1, 2:M3]));
            sqrt(2).*(imag.(v[M1+1, 1, 2:M3]));
            sqrt(2).*(real.(v[M1+1, M2+1, 2:M3]));
            sqrt(2).*(imag.(v[M1+1, M2+1, 2:M3]));
            sqrt(2).*(real.(v[1, 2:M2, 1]));
            sqrt(2).*(imag.(v[1, 2:M2, 1]));
            sqrt(2).*(real.(v[1, 2:M2, M3+1]));
            sqrt(2).*(imag.(v[1, 2:M2, M3+1]));
            sqrt(2).*(real.(v[M1+1, 2:M2, 1]));
            sqrt(2).*(imag.(v[M1+1, 2:M2, 1]));
            sqrt(2).*(real.(v[M1+1, 2:M2, M3+1]));
            sqrt(2).*(imag.(v[M1+1, 2:M2, M3+1]));
            sqrt(2).*(real.(v[2:M1, 1, 1]));
            sqrt(2).*(imag.(v[2:M1, 1, 1]));
            sqrt(2).*(real.(v[2:M1, 1, M3+1]));
            sqrt(2).*(imag.(v[2:M1, 1, M3+1]));
            sqrt(2).*(real.(v[2:M1, M2+1, 1]));
            sqrt(2).*(imag.(v[2:M1, M2+1, 1]));
            sqrt(2).*(real.(v[2:M1, M2+1, M3+1]));
            sqrt(2).*(imag.(v[2:M1, M2+1, M3+1]));
            reshape(sqrt(2).*(real.(v[1, 2:M2, 2:M3])), Int((M2-1)*(M3-1)));
            reshape(sqrt(2).*(imag.(v[1, 2:M2, 2:M3])), Int((M2-1)*(M3-1)));
            reshape(sqrt(2).*(real.(v[1, Int(M2+2):N2, 2:M3])), Int((M2-1)*(M3-1)));
            reshape(sqrt(2).*(imag.(v[1, Int(M2+2):N2, 2:M3])), Int((M2-1)*(M3-1)));
            reshape(sqrt(2).*(real.(v[M1+1, 2:M2, 2:M3])), Int((M2-1)*(M3-1)));
            reshape(sqrt(2).*(imag.(v[M1+1, 2:M2, 2:M3])), Int((M2-1)*(M3-1)));
            reshape(sqrt(2).*(real.(v[M1+1, Int(M2+2):N2, 2:M3])), Int((M2-1)*(M3-1)));
            reshape(sqrt(2).*(imag.(v[M1+1, Int(M2+2):N2, 2:M3])), Int((M2-1)*(M3-1)));
            reshape(sqrt(2).*(real.(v[2:M1, 1, 2:M3])), Int((M1-1)*(M3-1)));
            reshape(sqrt(2).*(imag.(v[2:M1, 1, 2:M3])), Int((M1-1)*(M3-1)));
            reshape(sqrt(2).*(real.(v[Int(M1+2):N1, 1, 2:M3])), Int((M1-1)*(M3-1)));
            reshape(sqrt(2).*(imag.(v[Int(M1+2):N1, 1, 2:M3])), Int((M1-1)*(M3-1)));
            reshape(sqrt(2).*(real.(v[2:M1, M2+1, 2:M3])), Int((M1-1)*(M3-1)));
            reshape(sqrt(2).*(imag.(v[2:M1, M2+1, 2:M3])), Int((M1-1)*(M3-1)));
            reshape(sqrt(2).*(real.(v[Int(M1+2):N1, M2+1, 2:M3])), Int((M1-1)*(M3-1)));
            reshape(sqrt(2).*(imag.(v[Int(M1+2):N1, M2+1, 2:M3])), Int((M1-1)*(M3-1)));
            reshape(sqrt(2).*(real.(v[2:M1, 2:M2, 1])), Int((M1-1)*(M2-1)));
            reshape(sqrt(2).*(imag.(v[2:M1, 2:M2, 1])), Int((M1-1)*(M2-1)));
            reshape(sqrt(2).*(real.(v[Int(M1+2):N1, 2:M2, 1])), Int((M1-1)*(M2-1)));
            reshape(sqrt(2).*(imag.(v[Int(M1+2):N1, 2:M2, 1])), Int((M1-1)*(M2-1)));
            reshape(sqrt(2).*(real.(v[2:M1, 2:M2, M3+1])), Int((M1-1)*(M2-1)));
            reshape(sqrt(2).*(imag.(v[2:M1, 2:M2, M3+1])), Int((M1-1)*(M2-1)));
            reshape(sqrt(2).*(real.(v[Int(M1+2):N1, 2:M2, M3+1])), Int((M1-1)*(M2-1)));
            reshape(sqrt(2).*(imag.(v[Int(M1+2):N1, 2:M2, M3+1])), Int((M1-1)*(M2-1)));
            reshape(sqrt(2).*(real.(v[2:M1, 2:M2, 2:M3])), Int((M1-1)*(M2-1)*(M3-1)));
            reshape(sqrt(2).*(imag.(v[2:M1, 2:M2, 2:M3])), Int((M1-1)*(M2-1)*(M3-1)));
            reshape(sqrt(2).*(real.(v[Int(M1+2):N1, 2:M2, 2:M3])), Int((M1-1)*(M2-1)*(M3-1)));
            reshape(sqrt(2).*(imag.(v[Int(M1+2):N1, 2:M2, 2:M3])), Int((M1-1)*(M2-1)*(M3-1)));
            reshape(sqrt(2).*(real.(v[2:M1, Int(M2+2):N2, 2:M3])), Int((M1-1)*(M2-1)*(M3-1)));
            reshape(sqrt(2).*(imag.(v[2:M1, Int(M2+2):N2, 2:M3])), Int((M1-1)*(M2-1)*(M3-1)));
            reshape(sqrt(2).*(real.(v[Int(M1+2):N1, Int(M2+2):N2, 2:M3])), Int((M1-1)*(M2-1)*(M3-1)));
            reshape(sqrt(2).*(imag.(v[Int(M1+2):N1, Int(M2+2):N2, 2:M3])), Int((M1-1)*(M2-1)*(M3-1)))];
    return beta
end


# mapping beta to DFT
# @param dim The dimension of the problem (dim = 1, 2, 3)
# @param size The size of each dimension of the problem
#(we only consider the cases when the sizes are even for all the dimenstions)
#(size is a tuple, e.g. size = (10, 20, 30))
# @param beta A 1-dimensional real vector with length equal to the product of size

# @details This fucnction maps beta to DFT

# @return DFT DFT shares the same size as param sizes

# @example
# >dim = 2;
# >size1 = (6, 8);
# >x = randn(6, 8);
# >v = fft(x)/sqrt(prod(size1));
# >beta = DFT_to_beta(dim, size1, v);
# >w = beta_to_DFT(dim, size1, beta); (w should be equal to v)

function beta_to_DFT(dim, size, beta)
    if (dim == 1)
        return beta_to_DFT_1d(beta, size)
    elseif (dim == 2)
        return beta_to_DFT_2d(beta, size)
    elseif (dim == 3)
        return beta_to_DFT_3d(beta, size)
    end
end

# 1 dim
function beta_to_DFT_1d_wei(beta, size)
    N = size[1]
    M = N ÷ 2
    v = [beta[1];
         (beta[3: M+1] .+ im .* beta[M+2:N]) ./ sqrt(2);
         beta[2];
         reverse((beta[3: M+1] .- im .* beta[M+2:N]) ./ sqrt(2))]
    return v
end

function beta_to_DFT_1d!(v, beta, size)
    N = size[1]
    M = N ÷ 2
    v[1] = beta[1]
    for i = 2:M
        v[i] = (beta[i+1] + im * beta[M+i]) / sqrt(2)
    end
    v[M+1] = beta[2]
    for i = 2:M
        v[N-i+2] = (beta[i+1] - im * beta[M+i]) / sqrt(2)
    end
    return v
end

function beta_to_DFT_1d(beta, size)
    N = size[1]
    v = Vector{ComplexF64}(undef, N)
    beta_to_DFT_1d!(v, beta, size)
end

# 2 dim
function beta_to_DFT_2d(beta, size)
    N1 = size[1]
    N2 = size[2]
    M1 = N1 ÷ 2
    M2 = N2 ÷ 2
    v = Matrix{Complex{Float64}}(undef, N1, N2)
    v[:,1] = [beta[1];
              ((beta[4+4*(M2-1)+1:4+4*(M2-1)+(M1-1)]).+(im.*(beta[Int(4+4*(M2-1)+(M1-1)+1):Int(4+4*(M2-1)+2*(M1-1))])))./sqrt(2);
              beta[3];
              reverse(((beta[Int(4+4*(M2-1)+1):Int(4+4*(M2-1)+(M1-1))]).-(im.*(beta[Int(4+4*(M2-1)+(M1-1)+1):Int(4+4*(M2-1)+2*(M1-1))])))./sqrt(2))]
    v[:,2:M2] = [transpose((beta[Int(4+1):Int(4+M2-1)]).+(im.*(beta[Int(4+(M2-1)+1):Int(4+2*(M2-1))])))./sqrt(2);
                 reshape(((beta[Int(4+4*(M2-1)+4*(M1-1)+1):Int(4+4*(M2-1)+4*(M1-1)+(M1-1)*(M2-1))]).+(im.*(beta[Int(4+4*(M2-1)+4*(M1-1)+(M1-1)*(M2-1)+1):Int(4+4*(M2-1)+4*(M1-1)+2*(M1-1)*(M2-1))])))./sqrt(2), Int(M1-1), Int(M2-1));
                 transpose((beta[Int(4+2*(M2-1)+1):Int(4+3*(M2-1))]).+(im.*(beta[Int(4+3*(M2-1)+1):Int(4+4*(M2-1))])))./sqrt(2);
                 reverse(reverse(reshape(((beta[Int(4+4*(M2-1)+4*(M1-1)+2*(M1-1)*(M2-1)+1):Int(4+4*(M2-1)+4*(M1-1)+3*(M1-1)*(M2-1))]).-(im.*(beta[Int(4+4*(M2-1)+4*(M1-1)+3*(M1-1)*(M2-1)+1):Int(N1*N2)])))./sqrt(2), Int(M1-1), Int(M2-1)), dims = 1), dims = 2)]
    v[:,M2+1] = [beta[2];
                 ((beta[Int(4+4*(M2-1)+2*(M1-1)+1):Int(4+4*(M2-1)+3*(M1-1))]).+(im.*(beta[Int(4+4*(M2-1)+3*(M1-1)+1):Int(4+4*(M2-1)+4*(M1-1))])))./sqrt(2);
                 beta[4];
                 reverse(((beta[Int(4+4*(M2-1)+2*(M1-1)+1):Int(4+4*(M2-1)+3*(M1-1))]).-(im.*(beta[Int(4+4*(M2-1)+3*(M1-1)+1):Int(4+4*(M2-1)+4*(M1-1))])))./sqrt(2), dims = 1)]
    v[:, M2+2:N2] = [transpose(reverse(conj.(v[1,2:M2])));
                     reverse(reverse(conj.(v[M1+2:N1,2:M2]), dims = 2), dims = 1);
                     transpose(reverse(conj.(v[M1+1,2:M2])));
                     reverse(reverse(conj.(v[2:M1,2:M2]), dims = 2), dims = 1)]
    return v
end

# 3 dim
function beta_to_DFT_3d(beta, size)
    N1 = size[1]
    N2 = size[2]
    N3 = size[3]
    M1 = N1 ÷ 2
    M2 = N2 ÷ 2
    M3 = N3 ÷ 2
    v = Array{Complex{Float64}, 3}(undef, N1, N2, N3)

    v[:, 1, 1] = [beta[1];
                  ((beta[Int(8+8*(M3-1)+8*(M2-1)+1):Int(8+8*(M3-1)+8*(M2-1)+(M1-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+(M1-1)+1):Int(8+8*(M3-1)+8*(M2-1)+2*(M1-1))])))./sqrt(2);
                  beta[5];
                  reverse(((beta[Int(8+8*(M3-1)+8*(M2-1)+1):Int(8+8*(M3-1)+8*(M2-1)+(M1-1))]).-(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+(M1-1)+1):Int(8+8*(M3-1)+8*(M2-1)+2*(M1-1))])))./sqrt(2))];

    v[:, 2:M2, 1] = [transpose(((beta[Int(8+8*(M3-1)+1):Int(8+8*(M3-1)+(M2-1))]).+(im.*(beta[Int(8+8*(M3-1)+(M2-1)+1):Int(8+8*(M3-1)+2*(M2-1))])))./sqrt(2));
                     reshape(((beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+(M1-1)*(M2-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+(M1-1)*(M2-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+2*(M1-1)*(M2-1))])))./sqrt(2), Int(M1-1), Int(M2-1));
                     transpose(((beta[Int(8+8*(M3-1)+4*(M2-1)+1):Int(8+8*(M3-1)+5*(M2-1))]).+(im.*(beta[Int(8+8*(M3-1)+5*(M2-1)+1):Int(8+8*(M3-1)+6*(M2-1))])))./sqrt(2));
                     reshape(((beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+2*(M1-1)*(M2-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+3*(M1-1)*(M2-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+3*(M1-1)*(M2-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+4*(M1-1)*(M2-1))])))./sqrt(2), Int(M1-1), Int(M2-1))];

    v[:, M2+1, 1] = [beta[3];
                     ((beta[Int(8+8*(M3-1)+8*(M2-1)+4*(M1-1)+1):Int(8+8*(M3-1)+8*(M2-1)+5*(M1-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+5*(M1-1)+1):Int(8+8*(M3-1)+8*(M2-1)+6*(M1-1))])))./sqrt(2);
                     beta[7];
                     reverse(((beta[Int(8+8*(M3-1)+8*(M2-1)+4*(M1-1)+1):Int(8+8*(M3-1)+8*(M2-1)+5*(M1-1))]).-(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+5*(M1-1)+1):Int(8+8*(M3-1)+8*(M2-1)+6*(M1-1))])))./sqrt(2))];

    v[:, Int(M2+2):N2, 1] = [transpose(reverse(conj.(v[1, 2:M2, 1])));
                             reverse(reverse(conj.(v[Int(M1+2):N1, 2:M2, 1]), dims = 1), dims = 2);
                             transpose(reverse(conj.(v[M1+1, 2:M2, 1])));
                             reverse(reverse(conj.(v[2:M1, 2:M2, 1]), dims = 1), dims = 2)];


    v[:, 1, M3+1] = [beta[2];
                     ((beta[Int(8+8*(M3-1)+8*(M2-1)+2*(M1-1)+1):Int(8+8*(M3-1)+8*(M2-1)+3*(M1-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+3*(M1-1)+1):Int(8+8*(M3-1)+8*(M2-1)+4*(M1-1))])))./sqrt(2);
                     beta[6];
                     reverse(((beta[Int(8+8*(M3-1)+8*(M2-1)+2*(M1-1)+1):Int(8+8*(M3-1)+8*(M2-1)+3*(M1-1))]).-(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+3*(M1-1)+1):Int(8+8*(M3-1)+8*(M2-1)+4*(M1-1))])))./sqrt(2))];

    v[:, 2:M2, M3+1] = [transpose(((beta[Int(8+8*(M3-1)+2*(M2-1)+1):Int(8+8*(M3-1)+3*(M2-1))]).+(im.*(beta[Int(8+8*(M3-1)+3*(M2-1)+1):Int(8+8*(M3-1)+4*(M2-1))])))./sqrt(2));
                        reshape(((beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+4*(M1-1)*(M2-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+5*(M1-1)*(M2-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+5*(M1-1)*(M2-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+6*(M1-1)*(M2-1))])))./sqrt(2), Int(M1-1), Int(M2-1));
                        transpose(((beta[Int(8+8*(M3-1)+6*(M2-1)+1):Int(8+8*(M3-1)+7*(M2-1))]).+(im.*(beta[Int(8+8*(M3-1)+7*(M2-1)+1):Int(8+8*(M3-1)+8*(M2-1))])))./sqrt(2));
                        reshape(((beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+6*(M1-1)*(M2-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+7*(M1-1)*(M2-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+7*(M1-1)*(M2-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+8*(M1-1)*(M2-1))])))./sqrt(2), Int(M1-1), Int(M2-1))];

    v[:, M2+1, M3+1] = [beta[4];
                        ((beta[Int(8+8*(M3-1)+8*(M2-1)+6*(M1-1)+1):Int(8+8*(M3-1)+8*(M2-1)+7*(M1-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+7*(M1-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1))])))./sqrt(2);
                        beta[8];
                        reverse(((beta[Int(8+8*(M3-1)+8*(M2-1)+6*(M1-1)+1):Int(8+8*(M3-1)+8*(M2-1)+7*(M1-1))]).-(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+7*(M1-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1))])))./sqrt(2))];

    v[:, Int(M2+2):N2, M3+1] = [transpose(reverse(conj.(v[1, 2:M2, M3+1])));
                                reverse(reverse(conj.(v[Int(M1+2):N1, 2:M2, M3+1]), dims = 1), dims = 2);
                                transpose(reverse(conj.(v[M1+1, 2:M2, M3+1])));
                                reverse(reverse(conj.(v[2:M1, 2:M2, M3+1]), dims = 1), dims = 2)];


    v[:, 1, 2:M3] = [transpose(((beta[9:Int(8+(M3-1))]).+(im.*(beta[Int(8+(M3-1)+1):Int(8+2*(M3-1))])))./sqrt(2));
                     reshape(((beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+(M1-1)*(M3-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+(M1-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+2*(M1-1)*(M3-1))])))./sqrt(2), Int(M1-1), Int(M3-1));
                     transpose(((beta[Int(8+4*(M3-1)+1):Int(8+5*(M3-1))]).+(im.*(beta[Int(8+5*(M3-1)+1):Int(8+6*(M3-1))])))./sqrt(2));
                     reshape(((beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+2*(M1-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+3*(M1-1)*(M3-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+3*(M1-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+4*(M1-1)*(M3-1))])))./sqrt(2), Int(M1-1), Int(M3-1))];

    v[:, 1, Int(M3+2):N3] = [transpose(reverse(conj.(v[1, 1, 2:M3])));
                             reverse(reverse(conj.(v[Int(M1+2):N1, 1, 2:M3]), dims = 1), dims = 2);
                             transpose(reverse(conj.(v[M1+1, 1, 2:M3])));
                             reverse(reverse(conj.(v[2:M1, 1, 2:M3]), dims = 1), dims = 2)];

#    v[:, M2+1, 2:M3] = [transpose(((beta[9:Int(8+(M3-1))]).+(im.*(beta[Int(8+(M3-1)+1):Int(8+2*(M3-1))])))./sqrt(2));
     v[:, M2+1, 2:M3] = [transpose(((beta[Int(8+2*(M3-1)+1):Int(8+3*(M3-1))]).+(im.*(beta[Int(8+3*(M3-1)+1):Int(8+4*(M3-1))])))./sqrt(2));
                         #reshape(((beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+(M1-1)*(M3-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+(M1-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+2*(M1-1)*(M3-1))])))./sqrt(2), Int(M1-1), Int(M3-1));
                         reshape(((beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+4*(M1-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+5*(M1-1)*(M3-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+5*(M1-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+6*(M1-1)*(M3-1))])))./sqrt(2), Int(M1-1), Int(M3-1));
                         #transpose(((beta[Int(8+4*(M3-1)+1):Int(8+5*(M3-1))]).+(im.*(beta[Int(8+5*(M3-1)+1):Int(8+6*(M3-1))])))./sqrt(2));
                         transpose(((beta[Int(8+6*(M3-1)+1):Int(8+7*(M3-1))]).+(im.*(beta[Int(8+7*(M3-1)+1):Int(8+8*(M3-1))])))./sqrt(2));
                         reshape(((beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+6*(M1-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+7*(M1-1)*(M3-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+7*(M1-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1))])))./sqrt(2), Int(M1-1), Int(M3-1))];
                         #reshape(((beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+2*(M1-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+3*(M1-1)*(M3-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+3*(M1-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+4*(M1-1)*(M3-1))])))./sqrt(2), Int(M1-1), Int(M3-1))];

    v[:, M2+1, Int(M3+2):N3] = [transpose(reverse(conj.(v[1, M2+1, 2:M3])));
                                reverse(reverse(conj.(v[Int(M1+2):N1, M2+1, 2:M3]), dims = 1), dims = 2);
                                transpose(reverse(conj.(v[M1+1, M2+1, 2:M3])));
                                reverse(reverse(conj.(v[2:M1, M2+1, 2:M3]), dims = 1), dims = 2)];

    v[1, 2:M2, 2:M3] = reshape(((beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+(M2-1)*(M3-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+(M2-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+2*(M2-1)*(M3-1))])))./sqrt(2), Int(M2-1), Int(M3-1));
    v[1, Int(M2+2):N2, 2:M3] = reshape(((beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+2*(M2-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+3*(M2-1)*(M3-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+3*(M2-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+4*(M2-1)*(M3-1))])))./sqrt(2), Int(M2-1), Int(M3-1));
    v[1, 2:M2, Int(M3+2):N3] = reverse(reverse(conj.(v[1, Int(M2+2):N2, 2:M3]), dims = 1), dims = 2);
    v[1, Int(M2+2):N2, Int(M3+2):N3] = reverse(reverse(conj.(v[1, 2:M2, 2:M3]), dims = 1), dims = 2);

    v[M1+1, 2:M2, 2:M3] = reshape(((beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+4*(M2-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+5*(M2-1)*(M3-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+5*(M2-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+6*(M2-1)*(M3-1))])))./sqrt(2), Int(M2-1), Int(M3-1));
    v[M1+1, Int(M2+2):N2, 2:M3] = reshape(((beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+6*(M2-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+7*(M2-1)*(M3-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+7*(M2-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1))])))./sqrt(2), Int(M2-1), Int(M3-1));
    v[M1+1, 2:M2, Int(M3+2):N3] = reverse(reverse(conj.(v[M1+1, Int(M2+2):N2, 2:M3]), dims = 1), dims = 2);
    v[M1+1, Int(M2+2):N2, Int(M3+2):N3] = reverse(reverse(conj.(v[M1+1, 2:M2, 2:M3]), dims = 1), dims = 2);

    v[2:M1, 2:M2, 2:M3] = reshape(((beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+8*(M1-1)*(M2-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+8*(M1-1)*(M2-1)+(M1-1)*(M2-1)*(M3-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+8*(M1-1)*(M2-1)+(M1-1)*(M2-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+8*(M1-1)*(M2-1)+2*(M1-1)*(M2-1)*(M3-1))])))./sqrt(2), Int(M1-1), Int(M2-1), Int(M3-1));
    v[Int(M1+2):N1, Int(M2+2):N2, Int(M3+2):N3] = reverse(reverse(reverse(conj.(v[2:M1, 2:M2, 2:M3]), dims = 1), dims = 2), dims = 3);

    v[Int(M1+2):N1, 2:M2, 2:M3] = reshape(((beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+8*(M1-1)*(M2-1)+2*(M1-1)*(M2-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+8*(M1-1)*(M2-1)+3*(M1-1)*(M2-1)*(M3-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+8*(M1-1)*(M2-1)+3*(M1-1)*(M2-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+8*(M1-1)*(M2-1)+4*(M1-1)*(M2-1)*(M3-1))])))./sqrt(2), Int(M1-1), Int(M2-1), Int(M3-1));
    v[2:M1, Int(M2+2):N2, Int(M3+2):N3] = reverse(reverse(reverse(conj.(v[Int(M1+2):N1, 2:M2, 2:M3]), dims = 1), dims = 2), dims = 3);

    v[2:M1, Int(M2+2):N2, 2:M3] = reshape(((beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+8*(M1-1)*(M2-1)+4*(M1-1)*(M2-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+8*(M1-1)*(M2-1)+5*(M1-1)*(M2-1)*(M3-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+8*(M1-1)*(M2-1)+5*(M1-1)*(M2-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+8*(M1-1)*(M2-1)+6*(M1-1)*(M2-1)*(M3-1))])))./sqrt(2), Int(M1-1), Int(M2-1), Int(M3-1));
    v[Int(M1+2):N1, 2:M2, Int(M3+2):N3] = reverse(reverse(reverse(conj.(v[2:M1, Int(M2+2):N2, 2:M3]), dims = 1), dims = 2), dims = 3);

    v[Int(M1+2):N1, Int(M2+2):N2, 2:M3] = reshape(((beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+8*(M1-1)*(M2-1)+6*(M1-1)*(M2-1)*(M3-1)+1):Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+8*(M1-1)*(M2-1)+7*(M1-1)*(M2-1)*(M3-1))]).+(im.*(beta[Int(8+8*(M3-1)+8*(M2-1)+8*(M1-1)+8*(M2-1)*(M3-1)+8*(M1-1)*(M3-1)+8*(M1-1)*(M2-1)+7*(M1-1)*(M2-1)*(M3-1)+1):Int(N1*N2*N3)])))./sqrt(2), Int(M1-1), Int(M2-1), Int(M3-1));
    v[2:M1, 2:M2, Int(M3+2):N3] = reverse(reverse(reverse(conj.(v[Int(M1+2):N1, Int(M2+2):N2, 2:M3]), dims = 1), dims= 2), dims = 3);

    return v
end
