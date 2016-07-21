 var app = angular.module('myApp', []);

app.controller('MainCtrl', function($scope, $window, $interval){
    // some chart data
    $scope.charts = {data: [10, 6, 7, 5, 10, 1, 13, 6, 2, 8]};

    // wait for window resizes
    angular.element($window).on('resize', $scope.$apply.bind($scope));
});