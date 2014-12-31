angular.module("testApp",["goban"])
    .controller("ctrl",myCtrl);

function myCtrl ($scope,$goban) {
  $scope.goban = $goban.$default({
    webConfig: true,
    title: 'physics',
    myI: 4
  });

  $goban.init();
}