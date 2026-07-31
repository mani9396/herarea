from rest_framework.pagination import PageNumberPagination, LimitOffsetPagination

class StandardResultsSetPagination(PageNumberPagination):
    """
    Production-grade PageNumber pagination optimized for dashboard tables and standard list feeds.
    Supports client override via ?page_size=20 (up to a safe maximum of 100 items per call).
    """
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100


class FlexibleLimitOffsetPagination(LimitOffsetPagination):
    """
    Production-grade LimitOffset pagination optimized for Flutter mobile infinite scroll implementations
    (ListView.builder with ScrollController) via ?limit=20&offset=40.
    """
    default_limit = 20
    limit_query_param = 'limit'
    offset_query_param = 'offset'
    max_limit = 100
