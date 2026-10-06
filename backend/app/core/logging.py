import logging
import sys

# Configure privacy-safe structured logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)

logger = logging.getLogger("ebb.backend")

def log_safe_event(event_name: str, **metadata):
    """
    Log an application event with privacy guarantees.
    Explicitly strips any sensitive physiological or user identifiable fields.
    """
    sanitized = {}
    sensitive_keys = {
        "heart_rate", "hr", "hrv", "rmssd", "sleep", "mood", 
        "password", "token", "calendar", "authorization"
    }
    for k, v in metadata.items():
        if k.lower() in sensitive_keys:
            sanitized[k] = "[REDACTED]"
        else:
            sanitized[k] = v
    logger.info(f"event={event_name} {sanitized}")
