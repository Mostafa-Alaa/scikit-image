#cython: cdivision=True
#cython: boundscheck=False
#cython: nonecheck=False
#cython: wraparound=False
import numpy as np
cimport numpy as cnp
from libc.float cimport DBL_MAX

from skimage.color import rgb2grey
from skimage.util import img_as_float


def moravec(image, int block_size=1):
    """Compute Moravec response image.

    This interest operator is comparatively fast but not rotation invariant.

    Parameters
    ----------
    image : ndarray
        Input image.
    block_size : int, optional
        Block size for mean filtering the squared gradients.

    Returns
    -------
    coordinates : (N, 2) array
        `(row, column)` coordinates of interest points.

    Examples
    -------
    >>> from skimage.feature import moravec, peak_local_max
    >>> square = np.zeros([7, 7])
    >>> square[3, 3] = 1
    >>> square
    array([[ 0.,  0.,  0.,  0.,  0.,  0.,  0.],
           [ 0.,  0.,  0.,  0.,  0.,  0.,  0.],
           [ 0.,  0.,  0.,  0.,  0.,  0.,  0.],
           [ 0.,  0.,  0.,  1.,  0.,  0.,  0.],
           [ 0.,  0.,  0.,  0.,  0.,  0.,  0.],
           [ 0.,  0.,  0.,  0.,  0.,  0.,  0.],
           [ 0.,  0.,  0.,  0.,  0.,  0.,  0.]])
    >>> moravec(square)
    array([[ 0.,  0.,  0.,  0.,  0.,  0.,  0.],
           [ 0.,  0.,  0.,  0.,  0.,  0.,  0.],
           [ 0.,  0.,  1.,  1.,  1.,  0.,  0.],
           [ 0.,  0.,  1.,  2.,  1.,  0.,  0.],
           [ 0.,  0.,  1.,  1.,  1.,  0.,  0.],
           [ 0.,  0.,  0.,  0.,  0.,  0.,  0.],
           [ 0.,  0.,  0.,  0.,  0.,  0.,  0.]])
    """

    cdef int rows = image.shape[0]
    cdef int cols = image.shape[1]

    cdef cnp.ndarray[dtype=cnp.double_t, ndim=2, mode='c'] cimage, out

    if image.ndim == 3:
        cimage = rgb2grey(image)
    cimage = np.ascontiguousarray(img_as_float(image))

    out = np.zeros_like(image)

    cdef double* image_data = <double*>cimage.data
    cdef double* out_data = <double*>out.data

    cdef double msum, min_msum
    cdef int r, c, br, bc, mr, mc, a, b
    for r in range(2 * block_size, rows - 2 * block_size):
        for c in range(2 * block_size, cols - 2 * block_size):
            min_msum = DBL_MAX
            for br in range(r - block_size, r + block_size + 1):
                for bc in range(c - block_size, c + block_size + 1):
                    if br != r and bc != c:
                        msum = 0
                        for mr in range(- block_size, block_size + 1):
                            for mc in range(- block_size, block_size + 1):
                                a = (r + mr) * cols + c + mc
                                b = (br + mr) * cols + bc + mc
                                msum += (image_data[a] - image_data[b]) ** 2
                        min_msum = min(msum, min_msum)

            out_data[r * cols + c] = min_msum

    return out
