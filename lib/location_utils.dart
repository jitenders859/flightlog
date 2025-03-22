import 'dart:math';

class LocationUtils {
  // Calculate distance between two coordinates using Haversine formula
  static double calculateDistance(
    double startLatitude, 
    double startLongitude, 
    double endLatitude, 
    double endLongitude
  ) {
    const int earthRadius = 6371000; // in meters
    
    // Convert degrees to radians
    double startLatRad = _degreesToRadians(startLatitude);
    double startLongRad = _degreesToRadians(startLongitude);
    double endLatRad = _degreesToRadians(endLatitude);
    double endLongRad = _degreesToRadians(endLongitude);
    
    // Calculate differences
    double latDiff = endLatRad - startLatRad;
    double longDiff = endLongRad - startLongRad;
    
    // Haversine formula
    double a = sin(latDiff / 2) * sin(latDiff / 2) +
               cos(startLatRad) * cos(endLatRad) *
               sin(longDiff / 2) * sin(longDiff / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    // Distance in meters
    return earthRadius * c;
  }
  
  // Format distance for display
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
    }
  }
  
  // Calculate heading/bearing between two points
  static double calculateHeading(
    double startLatitude, 
    double startLongitude, 
    double endLatitude, 
    double endLongitude
  ) {
    // Convert degrees to radians
    double startLatRad = _degreesToRadians(startLatitude);
    double startLongRad = _degreesToRadians(startLongitude);
    double endLatRad = _degreesToRadians(endLatitude);
    double endLongRad = _degreesToRadians(endLongitude);
    
    // Calculate y and x
    double y = sin(endLongRad - startLongRad) * cos(endLatRad);
    double x = cos(startLatRad) * sin(endLatRad) -
               sin(startLatRad) * cos(endLatRad) * cos(endLongRad - startLongRad);
    
    // Calculate bearing
    double bearing = atan2(y, x);
    
    // Convert to degrees
    double bearingDegrees = _radiansToDegrees(bearing);
    
    // Normalize to 0-360
    return (bearingDegrees + 360) % 360;
  }
  
  // Get cardinal direction from heading
  static String getCardinalDirection(double heading) {
    const List<String> directions = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'
    ];
    
    int index = ((heading + 11.25) % 360 / 22.5).floor();
    return directions[index];
  }
  
  // Calculate a point at a given distance and bearing from start point
  static Map<String, double> calculateDestination(
    double startLatitude,
    double startLongitude,
    double distance, // in meters
    double bearing
  ) {
    const double earthRadius = 6371000; // in meters
    
    // Convert to radians
    double startLatRad = _degreesToRadians(startLatitude);
    double startLongRad = _degreesToRadians(startLongitude);
    double bearingRad = _degreesToRadians(bearing);
    
    // Angular distance
    double angDist = distance / earthRadius;
    
    // Calculate new latitude
    double newLatRad = asin(
      sin(startLatRad) * cos(angDist) +
      cos(startLatRad) * sin(angDist) * cos(bearingRad)
    );
    
    // Calculate new longitude
    double newLongRad = startLongRad + atan2(
      sin(bearingRad) * sin(angDist) * cos(startLatRad),
      cos(angDist) - sin(startLatRad) * sin(newLatRad)
    );
    
    // Convert to degrees
    double newLatitude = _radiansToDegrees(newLatRad);
    double newLongitude = _radiansToDegrees(newLongRad);
    
    return {
      'latitude': newLatitude,
      'longitude': newLongitude,
    };
  }
  
  // Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
  
  // Convert radians to degrees
  static double _radiansToDegrees(double radians) {
    return radians * 180 / pi;
  }
}