# because reversed() didn't play ball with seqs
proc reverse*[T](xs: seq[T]): seq[T] =
  result = newSeq[T](xs.len)
  for i, x in xs:
      #result[^i-1] = x 
      result[xs.high-i] = x


# based on https://forum.nim-lang.org/t/2328

# sequence slicing similar to Python
type SeqView*[T] = object
  # originally was ref, but I had to change it, see below
  data*: seq[T]
  bounds*: Slice[int]

# for some reason, this didn't work properly, at least with JS
# proc box*[T](x: T): T =
#   new(result); 
#   result[] = x


#   # debug
#   echo "Box: " & $result[];
#   return result[];

iterator items*[T](sv: SeqView[T]): T =
  # debug
  #echo $sv.data;
  for pos in sv.bounds:
    try:
        yield sv.data[pos];
    except:
        echo "Something weird happened..." & $pos;

# proc sequed*[T](sv: SeqView[T]) : seq[T] =
#     var ret: seq[T];
#     # uses items() above
#     for el in sv.items():
#         echo $el;
#         ret.add(el)

#     return ret

#var
#    seq1 = @[1, 2, 3, 4, 5, 6]
#    sv = SeqView[int](data: box(seq1), bounds: 2..4);

#for el in sv:
#    echo el
