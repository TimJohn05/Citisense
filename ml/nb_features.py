"""Shared Naive Bayes + TF-IDF feature pipeline for CitiSense.

The exact numerics here (tokenizer, n-gram scheme, idf, l2 norm) are the
*parity contract* mirrored 1:1 by the Dart on-device classifier in
lib/services/nb_tfidf_classifier.dart. Change one side and the parity test
(fixtures to 1e-6) breaks — change both together.
"""

import math
import re
from collections import Counter, defaultdict
from typing import Dict, List, Optional, Sequence, Tuple

_token_re = re.compile(r"[^a-z0-9]+")


def tokenize(text: str) -> List[str]:
    """Lowercase, collapse non-alphanumeric runs to a single space, split."""
    lowered = text.lower()
    spaced = _token_re.sub(" ", lowered)
    return spaced.split()


def ngrams(tokens: Sequence[str], n: int = 2) -> List[str]:
    """Unigrams plus contiguous n-grams joined with an underscore."""
    grams: List[str] = list(tokens)
    for order in range(2, n + 1):
        for i in range(len(tokens) - order + 1):
            grams.append("_".join(tokens[i : i + order]))
    return grams


def build_vocab(
    corpus_grams: Sequence[Sequence[str]],
    min_df: int = 2,
    max_features: int = 12000,
) -> Tuple[List[str], Counter, Dict[str, int]]:
    """N-grams with document frequency >= min_df, ranked by total count then
    df (deterministic tie-break), capped at max_features."""
    df: Dict[str, int] = defaultdict(int)
    total = Counter()
    for doc in corpus_grams:
        for g in set(doc):
            df[g] += 1
        for g in doc:
            total[g] += 1
    vocab = [g for g, d in df.items() if d >= min_df]
    vocab.sort(key=lambda g: (-total[g], -df[g], g))
    if len(vocab) > max_features:
        vocab = vocab[:max_features]
    return vocab, total, df


def idf_map(vocab: Sequence[str], df: Dict[str, int], n_docs: int) -> Dict[str, float]:
    """smooth_idf: log((1 + N) / (1 + df)) + 1."""
    return {g: math.log((1 + n_docs) / (1 + df[g])) + 1 for g in vocab}


def tfidf_rows(
    corpus_grams: Sequence[Sequence[str]],
    vocab: Sequence[str],
    idf: Dict[str, float],
) -> List[Dict[int, float]]:
    """Per-document sparse {vocab_index: tf*idf} dicts, l2-normalized per row."""
    index = {g: i for i, g in enumerate(vocab)}
    rows: List[Dict[int, float]] = []
    for doc in corpus_grams:
        counts = Counter(doc)
        present = set(doc) & set(index)
        raw = {index[g]: counts[g] * idf[g] for g in present}
        norm2 = sum(v * v for v in raw.values())
        if norm2 > 0:
            inv = 1.0 / math.sqrt(norm2)
            rows.append({k: v * inv for k, v in raw.items()})
        else:
            rows.append({})
    return rows


def tfidf_matrix(
    corpus_grams: Sequence[Sequence[str]],
    corpus_vocab: Sequence[str],
    df: Dict[str, int],
    n_docs: int,
) -> Tuple[object, List[str], Dict[str, float]]:
    """Convenience: build + convert to scipy CSR (or plain list if scipy is
    unavailable). Returns (matrix, vocab, idf)."""
    idf = idf_map(corpus_vocab, df, n_docs)
    rows = tfidf_rows(corpus_grams, corpus_vocab, idf)
    try:
        import scipy.sparse as sp
    except ImportError:
        return rows, list(corpus_vocab), idf
    data: List[float] = []
    indices: List[int] = []
    indptr = [0]
    for row in rows:
        for idx, val in row.items():
            indices.append(idx)
            data.append(val)
        indptr.append(len(data))
    return (
        sp.csr_matrix((data, indices, indptr), shape=(len(rows), len(corpus_vocab))),
        list(corpus_vocab),
        idf,
    )


def gram_tokenizer(text: str) -> List[str]:
    """Tokenizer that returns n-grams (unigrams + bigrams), for sklearn use."""
    return ngrams(tokenize(text))