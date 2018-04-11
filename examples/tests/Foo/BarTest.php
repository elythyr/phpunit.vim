<?php

namespace Foo;

class BarTest extends \PHPUnit\Framework\TestCase
{
    /**
     * @test
     */
    public function it_should_succeed()
    {
        $this->assertTrue(true);
    }

    /**
     * @test
     */
    public function it_should_be_used_to_test_results()
    {
        //$this->assertTrue(true); // Ok
        //$this->assertTrue(false); // Failure
        // Warning
    }
}
