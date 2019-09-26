"""
    crossedDataFrame(namedtup)

Return a `DataFrame` obtained by crossing factors given in `namedtup`.

`namedtup` should be a named tuple of vectors of strings giving the levels.
```@example
crossedDataFrame((prec=["break","maintain"], load=["yes","no"]))
```
"""
function crossedDataFrame(namedtup)
    nms = keys(namedtup)
    rowtbl = NamedTuple{nms, NTuple{length(namedtup), String}}[]
    for pr in Iterators.product(values(namedtup)...)
        push!(rowtbl, NamedTuple{nms}(pr))
    end
    ctbl = Tables.columntable(rowtbl)
    DataFrame(NamedTuple{keys(ctbl)}(PooledArray.(values(ctbl))))
end

"""
    cyclicshift(v::AbstractVector, nrow)

Return an `eltype(v)` matrix of size `nrow` by `length(v)` with each column consisting
of `v` followed by a cyclic shift of `v` followed by ...

The return value is used to counterbalance levels of conditions in [`withinitem`](@ref).
```@example
cyclicshift('a':'d', 8)
```
"""
function cyclicshift(v::AbstractVector, nrow)
    vlen = length(v)
    [v[1 + (i + j) % vlen] for i in 0:(nrow - 1), j in 0:(vlen - 1)]
end

"""
    itemsubjdf(nitem, nsubj, expfactors)

Return a data frame with `nitem` items crossed with `nsubj` subjects and experimental factors
given by `expfactors`.  The experimental factors are in a crossed, balanced configuration within
subject and within item.
"""
function itemsubjdf(nitem, nsubj, expfactors)
    expfacdf = crossedDataFrame(expfactors)
    df = repeat(withinitem(nitem, expfacdf), outer=nsubj ÷ size(expfacdf,1))
    df.subj = repeat(PooledArray(nlevels(nsubj)), inner=nitem)
    df
end

"""
    nlevels(nlev, tag='S')

Return a `Vector{String}` of `tag` followed by `1:nlev` padded with zeros
```@example
show(nlevels(10))
```
"""
nlevels(nlev, tag='S') = string.(tag, lpad.(1:nlev, ndigits(nlev), '0'))

"""
    withinitem(nitem, df)

Return a `DataFrame` of `item` with `nitem` levels and balanced columns of conditions from `df`
"""
function withinitem(nitem, df)
    nrow = size(df, 1)
    q, r = divrem(nitem, nrow)
    iszero(r) || throw(ArgumentError("nitem = $nitem is not a multiple of nrow = $nrow"))
    value = df[vec(cyclicshift(1:nrow, nitem)), :]
    value.item = repeat(PooledArray(string.('I', lpad.(string.(1:nitem), ndigits(nitem), '0'))),
        outer=nrow)
    value
end
