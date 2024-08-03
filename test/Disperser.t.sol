// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TestDisperser} from "./helpers/TestDisperser.sol";
import {Disperser} from "../src/Disperser.sol";
import {Token} from "../src/mock/Token.sol";

contract GeneralDisperserTest is Test {
    TestDisperser testDisperser;
    Disperser disperser;
    Token token0;
    Token token1;

    uint badDisperserGasUsed;

    function setUp() public {
        testDisperser = new TestDisperser();
        disperser = new Disperser();

        (bool ok,) = address(testDisperser).call{value: 1 ether}("");
        assertEq(ok, true);

        (ok,) = address(disperser).call{value: 1 ether}("");
        assertEq(ok, true);
        
        token0 = new Token();
        token0.transfer(address(testDisperser), 1 ether);
        token0.transfer(address(disperser), 1 ether);

        token1 = new Token();
        token1.transfer(address(testDisperser), 1 ether);
        token1.transfer(address(disperser), 1 ether);
    }

    function test_UneconomicReceive() public {
        uint256 balanceThisBefore = address(this).balance;
        uint256 balanceDisperserBefore = address(testDisperser).balance;

        (bool ok,) = address(testDisperser).call{value: 1 ether}("");
        assertEq(ok, true);

        uint256 balanceThisAfter = address(this).balance;
        uint256 balanceDisperserAfter = address(testDisperser).balance;
        
        assertEq(balanceThisBefore - balanceThisAfter, 1 ether);
        assertEq(balanceDisperserAfter - balanceDisperserBefore, 1 ether);
    }

    function test_UneconomicRevertFromNotOwner() public {
        address alice = address(0x1);
        vm.prank(alice);

        vm.expectRevert("Ownable: not from owner");
        TestDisperser.DisperseInfo[] memory infos = new TestDisperser.DisperseInfo[](0);
        testDisperser.disperse(infos);
    }

    function test_UneconomicDisperse() public {
        address alice = address(0x2);
        address bob = address(0x3);
       
        TestDisperser.DisperseInfo[] memory infos = _getDisperseInfo();

        uint256 gasBefore = gasleft();
        testDisperser.disperse(infos);
        uint256 gasAfter = gasleft();

        badDisperserGasUsed = gasBefore - gasAfter;
        console.log(badDisperserGasUsed);

        assertEq(alice.balance, 1);
        assertEq(bob.balance, 1);
        assertEq(token0.balanceOf(alice), 1);
        assertEq(token0.balanceOf(bob), 1);
        assertEq(token1.balanceOf(alice), 1);
        assertEq(token1.balanceOf(bob), 1);
    }

    // Real disperser test block
    function test_Receive() public {
        uint256 balanceThisBefore = address(this).balance;
        uint256 balanceDisperserBefore = address(disperser).balance;

        (bool ok,) = address(disperser).call{value: 1 ether}("");
        assertEq(ok, true);

        uint256 balanceThisAfter = address(this).balance;
        uint256 balanceDisperserAfter = address(disperser).balance;
        
        assertEq(balanceThisBefore - balanceThisAfter, 1 ether);
        assertEq(balanceDisperserAfter - balanceDisperserBefore, 1 ether);
    }

    function test_RevertFromNotOwner() public {
        address alice = address(0x1);
        vm.prank(alice);

        vm.expectRevert();
        address(disperser).call("01");
    }

    function test_SingleEthTransfer() public {
        address alice = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);

        assertEq(alice.balance, 0);
        address(disperser).call(_parseDisperseInfo(_getDispersePlainEtherInfo()));

        assertEq(alice.balance, 1);
    }

    function test_Disperse() public {
        address alice = address(0x2);
        address bob = address(0x3);
       
        TestDisperser.DisperseInfo[] memory infos = _getDisperseInfo();

        uint256 gasBefore = gasleft();
        address(disperser).call(_parseDisperseInfo(infos));
        uint256 gasAfter = gasleft();

        assertEq(alice.balance, 1);
        assertEq(bob.balance, 1);
        assertEq(token0.balanceOf(alice), 1);
        assertEq(token0.balanceOf(bob), 1);
        assertEq(token1.balanceOf(alice), 1);
        assertEq(token1.balanceOf(bob), 1);

        badDisperserGasUsed = gasBefore - gasAfter;
        console.log(badDisperserGasUsed);
    }

    function _parseDisperseInfo(TestDisperser.DisperseInfo[] memory infos) internal returns (bytes memory) {
        bytes memory cData = abi.encodePacked(bytes1(uint8(infos.length)));

        for (uint i = 0; i < infos.length; i++) {
            TestDisperser.DisperseInfo memory info = infos[i];

            address token = info.token;
            cData = abi.encodePacked(cData, bytes20(uint160(token)));
            cData = abi.encodePacked(cData, bytes1(uint8(info.destinations.length)));
            for (uint j = 0; j < info.destinations.length; j++) {
                cData = abi.encodePacked(cData, bytes20(uint160(info.destinations[j])));
                cData = abi.encodePacked(cData, bytes32(info.amounts[j]));
            }
        }
        return cData;
    }

    function _getDisperseInfo() internal returns (TestDisperser.DisperseInfo[] memory) {
        address alice = address(0x2);
        address bob = address(0x3);

        address[] memory addresses = new address[](2);
        addresses[0] = alice;
        addresses[1] = bob;

        uint256[] memory destinations = new uint256[](2);
        destinations[0] = 1;
        destinations[1] = 1;
        
        TestDisperser.DisperseInfo[] memory infos = new TestDisperser.DisperseInfo[](3);
        infos[0] = TestDisperser.DisperseInfo(address(0), addresses, destinations);
        infos[1] = TestDisperser.DisperseInfo(address(token0), addresses, destinations);
        infos[2] = TestDisperser.DisperseInfo(address(token1), addresses, destinations);

        return infos;
    }


    function _getDispersePlainEtherInfo() internal returns (TestDisperser.DisperseInfo[] memory) {
        address alice = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        
        address[] memory addresses = new address[](1);
        addresses[0] = alice;

        uint256[] memory destinations = new uint256[](1);
        destinations[0] = 1;
        
        TestDisperser.DisperseInfo[] memory infos = new TestDisperser.DisperseInfo[](1);
        infos[0] = TestDisperser.DisperseInfo(address(0), addresses, destinations);

        return infos;
    }

}
